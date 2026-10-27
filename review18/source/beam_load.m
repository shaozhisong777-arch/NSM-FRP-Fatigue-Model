function [M, V] = beam_load(p, x, Q)
    % Calculate bending moment and shear for symmetric four-point loading.
    % Q is the total load at the two loading points, not one point load.
    % x is measured from the left support. Units: N and mm, giving N*mm.
    % This helper is not called by the current fatigue solver.

    if nargin < 3
        Q = p.Qmax;
    end

    % 1. Check positions before calculating the response.
    for point = 1:numel(x)
        if x(point) < 0 || x(point) > p.span
            error('cc19:load', 'x is outside the span.');
        end
    end

    M = zeros(size(x));
    V = zeros(size(x));
    reaction = Q / 2;
    rightLoadingPoint = p.span - p.shearSpan;

    % 2. Calculate each position, preserving the input array shape.
    for point = 1:numel(x)
        leftDistance = x(point);
        rightDistance = p.span - x(point);
        momentArm = min(leftDistance, rightDistance);
        momentArm = min(momentArm, p.shearSpan);
        M(point) = reaction * momentArm;

        if x(point) < p.shearSpan
            V(point) = reaction;
        end
        if x(point) > rightLoadingPoint
            V(point) = -reaction;
        end
        % At loading-point coordinates, retain the original zero convention.
    end
end