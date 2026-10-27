function tauM = bond_strength(p, localN)
    % Calculate the degraded peak bond stress at each node.
    % localN is the cycle count since local activation, not global cycles.
    % The fatigue law uses p.bondFatigueK and p.tauM0.

    % 1. Require a real numeric cycle history.
    if ~isnumeric(localN) || ~isreal(localN)
        error('cc19:history', 'Local cycles must be finite and nonnegative.');
    end
    for node = 1:numel(localN)
        if ~isfinite(localN(node)) || localN(node) < 0
            error('cc19:history', 'Local cycles must be finite and nonnegative.');
        end
    end

    % 2. Preserve the shape of the input cycle array.
    tauM = zeros(size(localN));

    % 3. Evaluate the original fatigue law one node at a time.
    for node = 1:numel(localN)
        cycles = max(localN(node), 1);
        peakStress = p.tauM0 * (1 - p.bondFatigueK * log10(cycles));
        tauM(node) = max(0, peakStress);
    end
end