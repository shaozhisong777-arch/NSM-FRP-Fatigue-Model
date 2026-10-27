function [active, amplitude] = active_nodes(p, peak, low, memory)
    % Identify nodes eligible for local fatigue cycle accumulation.
    % Check each bar, each anchor side, and each node separately.
    % This function does not update cycle counts or bond strength.

    active = cell(p.nBars, 2);
    amplitude = cell(p.nBars, 2);
    activationSlip = p.activationFraction * p.deltaM;

    for bar = 1:p.nBars
        for side = 1:2
            active{bar, side} = false(p.nCells + 1, 1);
            amplitude{bar, side} = zeros(p.nCells + 1, 1);

            % Skip constant loading, failed bars, or missing results.
            if p.Qmax == p.Qmin
                continue
            end
            if memory.failedFRP(bar)
                continue
            end
            if isempty(peak.fields{bar})
                continue
            end
            if isempty(low.fields{bar})
                continue
            end

            peakSide = peak.fields{bar}.sides{side};
            lowSide = low.fields{bar}.sides{side};

            for node = 1:p.nCells + 1
                % amplitude is the nonnegative peak-minus-valley range.
                slipRange = max(0, peakSide.slip(node) - lowSide.slip(node));
                amplitude{bar, side}(node) = slipRange;

                % A previously activated node retains its eligibility.
                reachedThreshold = memory.activated{bar, side}(node);
                if peakSide.maxSlip(node) > activationSlip
                    reachedThreshold = true;
                end

                % Even an activated node needs a sufficient cyclic range.
                if reachedThreshold
                    if slipRange > p.cyclicSlipTolerance
                        active{bar, side}(node) = true;
                    end
                end
            end
        end
    end
end