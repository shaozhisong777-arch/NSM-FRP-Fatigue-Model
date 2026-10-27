function k = crack_deformation(p, q)
    % Calculate crack opening, sliding, and displacement jumps.
    % q is the vertical displacement jump, not the midspan deflection.
    % This function does not calculate beam curvature.

    % 1. Keep the original 101 sampling points along the crack height.
    numberOfPoints = 101;
    y = linspace(0, p.crackHeight, numberOfPoints)';
    % Retain the original shape expression and its floating-point order.
    shape = (1 - y / p.crackHeight).^p.crackShapeExponent;
    opening = zeros(numberOfPoints, 1);
    sliding = zeros(numberOfPoints, 1);
    verticalJump = zeros(numberOfPoints, 1);
    horizontalJump = zeros(numberOfPoints, 1);

    % 2. Calculate the opening and sliding scale factors.
    w = q / p.kinematicDenominator;
    v = p.slidingRatio * w;
    horizontalScale = -w * sin(p.theta) + v * cos(p.theta);

    % 3. Calculate each sampled point separately.
    for point = 1:numberOfPoints
        opening(point) = w * shape(point);
        sliding(point) = v * shape(point);
        verticalJump(point) = q * shape(point);
        horizontalJump(point) = horizontalScale * shape(point);
    end

    % 4. Keep all original output fields and their order.
    k.y = y;
    k.shape = shape;
    k.opening = opening;
    k.sliding = sliding;
    k.verticalJump = verticalJump;
    k.horizontalJump = horizontalJump;
    k.wMax = w;
    k.vMax = v;
    k.q = q;
end
