function c = capacity_scan(p, memory)
    % Scan a loading path and report the largest finite sampled shear force.
    % This diagnostic is not an exact global capacity or test validation.

    % 1. Keep the original sorted, unique displacement samples.
    nearZeroPoints = linspace(0, 0.15, 12);
    fullRangePoints = linspace(0, p.maxQ, p.scanPoints);
    x = unique([0, nearZeroPoints, fullRangePoints]);
    numberOfPoints = numel(x);
    curve = NaN(numberOfPoints, 5);
    bad = 0;
    pathMemory = memory;

    % 2. Evaluate each point, carrying forward successful loading history.
    for point = 1:numberOfPoints
        st = trial(p, x(point), pathMemory, false);
        curve(point, 1) = x(point);
        if st.localOK
            curve(point, 2) = st.V;
            curve(point, 3) = st.Vc;
            curve(point, 4) = st.Vs;
            curve(point, 5) = st.Vnsm;
            pathMemory = st.memory;
        else
            % Leave failed force entries as NaN and retain previous history.
            bad = bad + 1;
        end
    end

    % 3. Find the largest finite sampled force with a simple loop.
    cap = NaN;
    q = NaN;
    foundValidPoint = false;
    for point = 1:numberOfPoints
        force = curve(point, 2);
        if isfinite(force)
            if ~foundValidPoint
                cap = force;
                q = curve(point, 1);
                foundValidPoint = true;
            elseif force > cap
                % A tie keeps the first point, as in the original max call.
                cap = force;
                q = curve(point, 1);
            end
        end
    end

    % 4. Preserve the output fields, column names, and status values.
    c.curve = curve;
    c.columns = {'q_mm', 'V_N', 'Vc_N', 'Vs_N', 'Vnsm_N'};
    c.sampledCapacity = cap;
    c.qAtSampledPeak = q;
    c.numericalFailures = bad;
    c.status = 'sampled_model_domain_capacity';
    if bad > 0
        c.status = 'incomplete_capacity_scan';
    end
end