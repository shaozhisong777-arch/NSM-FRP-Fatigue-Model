function [st, info] = cc19_state(p, memory, Vtarget, previousQ, unload)
    % 整梁平衡。目标Vtarget；找q使Vc+Vs+Vnsm=Vtarget，返回st和info。
    % Vtarget=Vc(q)+Vs(q)+V_NSM(q)
    if nargin < 4
        previousQ = 0;
    end
    if nargin < 5
        unload = false;
    end
    info = struct('ok', false, 'status', 'no_equilibrium_in_model_domain', 'capacity', NaN, ...
                  'numericalFailures', 0, 'message', '');
    st = [];
    if Vtarget > p.shearStrutLimit
        info.status = 'user_concrete_strut_limit';
        return
    end
    if Vtarget * p.shearSpan > p.flexuralMomentLimit
        info.status = 'user_flexural_limit';
        return
    end
    if unload
        lowerQ = 0;
        upperQ = max(previousQ, p.slipTolerance);
    else
        lowerQ = max(0, previousQ);
        upperQ = p.maxQ;
    end
    if lowerQ > upperQ
        info.status = 'opening_limit_reached';
        return
    end
    trialOpenings = unique([lowerQ, linspace(lowerQ, min(0.15, upperQ), 12), linspace(lowerQ, upperQ, p.scanPoints), upperQ]);
    trialOpenings = trialOpenings(trialOpenings >= lowerQ & trialOpenings <= upperQ);
    peak = -Inf;
    previousState = [];
    previousError = NaN;
    previousOpening = NaN;
    % 先扫描找上升支的变号区间，再二分；每个试算都使用同一份冻结历史。
    for i = 1:numel(trialOpenings)
        trialState = cc19_trial(p, trialOpenings(i), memory, unload);
        if ~trialState.localOK
            info.numericalFailures = info.numericalFailures + 1;
            previousState = [];
            continue
        end
        r = trialState.V - Vtarget;
        peak = max(peak, trialState.V);
        if abs(r) <= p.forceTolerance
            st = trialState;
            info.ok = true;
            break
        end
        if ~isempty(previousState) && previousError < 0 && r > 0
            left = previousOpening;
            right = trialOpenings(i);
            for it = 1:70
                mid = (left + right) / 2;
                z = cc19_trial(p, mid, memory, unload);
                if ~z.localOK
                    info.numericalFailures = info.numericalFailures + 1;
                    break
                end
                midError = z.V - Vtarget;
                if abs(midError) <= p.forceTolerance
                    st = z;
                    info.ok = true;
                    break
                end
                if midError > 0
                    right = mid;
                else
                    left = mid;
                end
                if right - left < p.slipTolerance
                    break
                end
            end
            if info.ok
                break
            end
        end
        previousState = trialState;
        previousError = r;
        previousOpening = trialOpenings(i);
    end
    info.capacity = peak;
    if info.ok
        st.forceResidual = abs(st.V - Vtarget);
        info.status = 'balanced';
    elseif info.numericalFailures > 0
        info.status = 'numerical_failure';
        info.message = 'An anchor solve did not converge; this is not classified as physical fatigue failure.';
    elseif isfinite(peak) && peak >= Vtarget
        info.status = 'branch_or_resolution_limit';
    else
        info.message = 'No ascending force-balanced root was found within the specified crack-opening domain.';
    end
end
