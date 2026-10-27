function [st, info] = state(p, memory, Vtarget, previousQ, unload)
% STATE Find q such that Vc(q) + Vs(q) + Vnsm(q) = Vtarget.
% Inputs and outputs match the uploaded cc19_state function.
% The four sections below are NUMERICAL steps, not material phases.
% Elastic, softening and residual bond branches are evaluated by cc19_trial.
% All trial evaluations use the same accepted memory; scans do not commit it.

%% Step 1. Prepare the status and define the search interval.
if nargin < 4
    previousQ = 0;
end
if nargin < 5
    unload = false;
end
st = [];
info.ok = false;
info.status = 'no_equilibrium_in_model_domain';
info.capacity = NaN;
info.numericalFailures = 0;
info.message = '';

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

%% Step 2. Scan trial points and look for an ascending sign change.
nearZeroPoints = linspace(lowerQ, min(0.15, upperQ), 12);
fullRangePoints = linspace(lowerQ, upperQ, p.scanPoints);
allPoints = unique([lowerQ, nearZeroPoints, fullRangePoints, upperQ]);
trialOpenings = [];
for i = 1:numel(allPoints)
    if allPoints(i) >= lowerQ && allPoints(i) <= upperQ
        trialOpenings(end + 1) = allPoints(i);
    end
end

sampledPeak = -Inf;
hasPreviousPoint = false;
previousError = NaN;
previousOpening = NaN;
for i = 1:numel(trialOpenings)
    q = trialOpenings(i);
    trialState = cc19_trial(p, q, memory, unload);
    if ~trialState.localOK
        info.numericalFailures = info.numericalFailures + 1;
        hasPreviousPoint = false;
        continue
    end

    forceError = trialState.V - Vtarget;
    sampledPeak = max(sampledPeak, trialState.V);
    if abs(forceError) <= p.forceTolerance
        st = trialState;
        info.ok = true;
        break
    end

    if hasPreviousPoint && previousError < 0 && forceError > 0
        % Step 3 is a local function in THIS file, not an extra .m file.
        [candidate, foundRoot, localFailures] = bisect_interval( ...
            p, memory, Vtarget, previousOpening, q, unload);
        info.numericalFailures = info.numericalFailures + localFailures;
        if foundRoot
            st = candidate;
            info.ok = true;
            break
        end
    end
    previousError = forceError;
    previousOpening = q;
    hasPreviousPoint = true;
end

%% Step 4. Return a balanced root or a specific diagnostic status.
% Legacy field name: capacity is only the largest VALID scanned force so far.
% It does not include every bisection point and is not a global capacity proof.
info.capacity = sampledPeak;
if info.ok
    st.forceResidual = abs(st.V - Vtarget);
    info.status = 'balanced';
elseif info.numericalFailures > 0
    info.status = 'numerical_failure';
    info.message = 'An anchor solve did not converge; this is not classified as physical fatigue failure.';
elseif isfinite(sampledPeak) && sampledPeak >= Vtarget
    info.status = 'branch_or_resolution_limit';
else
    info.message = 'No ascending force-balanced root was found within the specified crack-opening domain.';
end
end

function [st, foundRoot, numericalFailures] = bisect_interval(p, memory, Vtarget, leftQ, rightQ, unload)
%% Step 3. Bisect a bracket with negative left and positive right force error.
% A small interval alone is not enough: force residual must also be acceptable.
st = [];
foundRoot = false;
numericalFailures = 0;
for iteration = 1:70
    middleQ = (leftQ + rightQ) / 2;
    trialState = cc19_trial(p, middleQ, memory, unload);
    if ~trialState.localOK
        numericalFailures = numericalFailures + 1;
        return
    end
    forceError = trialState.V - Vtarget;
    if abs(forceError) <= p.forceTolerance
        st = trialState;
        foundRoot = true;
        return
    end
    if forceError > 0
        rightQ = middleQ;
    else
        leftQ = middleQ;
    end
    if rightQ - leftQ < p.slipTolerance
        return
    end
end
end
