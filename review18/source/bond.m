function [tau, k, zone] = bond(p, sMax, tauM)
    % Evaluate the three-stage bond envelope at each node.
    % sMax: maximum slip history; tauM: current peak bond stress.
    % tau: envelope stress; k: secant stiffness.
    % zone: 1 = elastic, 2 = softening, 3 = residual.

    % 1. Check the slip history one node at a time.
    for node = 1:numel(sMax)
        if sMax(node) < 0 || ~isfinite(sMax(node))
            error('cc19:slip', 'Invalid slip history.');
        end
    end

    % A scalar peak stress applies to every node.
    if isscalar(tauM)
        peakStress = tauM;
        tauM = zeros(size(sMax));
        for node = 1:numel(sMax)
            tauM(node) = peakStress;
        end
    end
    if ~isequal(size(tauM), size(sMax))
        error('cc19:slip', 'Bond arrays must have matching size.');
    end

    % 2. Prepare output arrays with the same shape as the input.
    tau = zeros(size(sMax));
    k = zeros(size(sMax));
    zone = ones(size(sMax));

    % 3. Calculate the stress and stiffness at each node.
    for node = 1:numel(sMax)
        slip = sMax(node);
        peakStress = max(tauM(node), 0);

        % Keep the residual stress below the degraded peak.
        % This inherited numerical rule is not a new fatigue law.
        residualStress = min(p.tauR, peakStress);

        if slip <= p.deltaM
            % Elastic branch, including the peak slip.
            tau(node) = peakStress * slip / p.deltaM;
            zone(node) = 1;
        elseif slip <= p.deltaU
            % Softening branch, including the ultimate slip.
            tau(node) = residualStress + (peakStress - residualStress) ...
                * (p.deltaU - slip) / (p.deltaU - p.deltaM);
            zone(node) = 2;
        else
            % Residual branch beyond the ultimate slip.
            tau(node) = residualStress;
            zone(node) = 3;
        end

        if slip == 0
            % Use the initial slope to avoid division by zero.
            k(node) = peakStress / p.deltaM;
        else
            % Keep the original protection for extremely small slips.
            k(node) = tau(node) / max(slip, realmin);
        end
    end
end