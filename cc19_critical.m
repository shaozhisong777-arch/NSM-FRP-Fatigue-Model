function c = cc19_critical(p, memory)
    % Diagnostic sampled capacity path; not a global capacity proof or test validation.
    % Preserve the original scan; one failed bar does not imply whole-beam failure.
    x = unique([0, linspace(0, 0.15, 12), linspace(0, p.maxQ, p.scanPoints)]);
    curve = NaN(numel(x), 5);
    bad = 0;
    pathMemory = memory;
    for i = 1:numel(x)
        st = trial(p, x(i), pathMemory, false);
        if st.localOK
            curve(i, :) = [x(i), st.V, st.Vc, st.Vs, st.Vnsm];
            pathMemory = st.memory;
        else
            bad = bad + 1;
            curve(i, 1) = x(i);
        end
    end
    valid = find(isfinite(curve(:, 2)));
    if isempty(valid)
        cap = NaN;
        q = NaN;
    else
        [cap, k] = max(curve(valid, 2));
        q = curve(valid(k), 1);
    end
    c = struct('curve', curve, 'columns', {{'q_mm', 'V_N', 'Vc_N', 'Vs_N', 'Vnsm_N'}}, ...
               'sampledCapacity', cap, 'qAtSampledPeak', q, 'numericalFailures', bad, ...
               'status', 'sampled_model_domain_capacity');
    if bad > 0
        c.status = 'incomplete_capacity_scan';
    end
end
