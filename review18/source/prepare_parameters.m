function p = prepare_parameters(p)
    % Check inputs and prepare crack, NSM, and stirrup geometry.
    % p stores both input parameters and calculated geometry.

    % 1. Check groups of input parameters using field-name lists.
    pos = {'width', 'depth', 'flangeWidth', 'flangeDepth', 'fc', 'Ec', 'ds', 'span', 'shearSpan', ...
           'crackHeight', 'crackShapeExponent', 'Ef', 'Af', 'perimeter', 'ffu', 'nsmSpacing', ...
           'Es', 'stirrupSpacing', 'steelTransferLength', 'fy', 'tauM0', 'deltaM', 'deltaU', ...
           'VcPeak', 'concreteRiseQ', 'concreteSofteningW', 'Qmax', 'maxQ', 'forceTolerance', ...
           'slipTolerance', 'localTolerance', 'maxOpeningStep', 'steelSNrefStress', ...
           'steelSNexponent', 'concreteSNrefStress', 'concreteSNexponent'};
    for k = 1:numel(pos)
        fieldName = pos{k};
        v = p.(fieldName);
        if ~isnumeric(v) || ~isreal(v) || ~isscalar(v) || ~isfinite(v) || v <= 0
            error('cc19:input', '%s must be finite and positive.', pos{k});
        end
    end
    nonneg = {'crackOriginX', 'slidingRatio', 'tauR', 'bondFatigueK', 'stirrupArea', ...
              'Qmin', 'concreteResidualRatio', 'nsmFirstX', 'stirrupFirstX', 'cyclicSlipTolerance'};
    for k = 1:numel(nonneg)
        fieldName = nonneg{k};
        v = p.(fieldName);
        if ~isnumeric(v) || ~isreal(v) || ~isscalar(v) || ~isfinite(v) || v < 0
            error('cc19:input', '%s must be finite and nonnegative.', nonneg{k});
        end
    end
    ints = {'Nmax', 'cycleStep', 'nCells', 'scanPoints', 'localMaxIterations', 'nsmFaces'};
    for k = 1:numel(ints)
        fieldName = ints{k};
        v = p.(fieldName);
        if ~isnumeric(v) || ~isscalar(v) || ~isfinite(v) || v < 1 || v ~= fix(v)
            error('cc19:input', '%s must be a positive integer.', ints{k});
        end
    end
    lim = {'coverCapacityPerBar', 'steelSNrefCycles', 'concreteSNrefCycles', ...
           'shearStrutLimit', 'flexuralMomentLimit'};
    for k = 1:numel(lim)
        fieldName = lim{k};
        v = p.(fieldName);
        if ~isnumeric(v) || ~isreal(v) || ~isscalar(v) || isnan(v) || v <= 0
            error('cc19:input', '%s must be positive or Inf.', lim{k});
        end
    end
    flags = {'nsmEnabled', 'makePlots', 'exportResults', 'verbose', 'computeCapacity'};
    for k = 1:numel(flags)
        fieldName = flags{k};
        v = p.(fieldName);
        if ~isscalar(v) || ~(isnumeric(v) || islogical(v)) || ~any(v == [0 1])
            error('cc19:input', '%s must be logical.', flags{k});
        end
    end
    % 2. Check related parameters in short, separate conditions.
    if p.nCells < 4 || p.scanPoints < 15
        error('cc19:input', 'Inconsistent geometry, angles, load range or bond parameters.');
    end
    if p.Qmin > p.Qmax || p.shearSpan > p.span / 2
        error('cc19:input', 'Inconsistent geometry, angles, load range or bond parameters.');
    end
    if p.ds >= p.depth || p.crackHeight > p.depth || p.flangeDepth >= p.depth
        error('cc19:input', 'Inconsistent geometry, angles, load range or bond parameters.');
    end
    if p.deltaU <= p.deltaM || p.tauR > p.tauM0 || p.concreteResidualRatio > 1
        error('cc19:input', 'Inconsistent geometry, angles, load range or bond parameters.');
    end
    if p.activationFraction <= 0 || p.activationFraction > 1 || ~isfinite(p.activationFraction)
        error('cc19:input', 'Inconsistent geometry, angles, load range or bond parameters.');
    end
    if ~isscalar(p.thetaDeg) || ~isfinite(p.thetaDeg) || p.thetaDeg <= 0 || p.thetaDeg >= 90
        error('cc19:input', 'Inconsistent geometry, angles, load range or bond parameters.');
    end
    if ~isscalar(p.alphaDeg) || ~isfinite(p.alphaDeg) || p.alphaDeg <= 0 || p.alphaDeg > 90
        error('cc19:input', 'Inconsistent geometry, angles, load range or bond parameters.');
    end
    if p.nsmYBottom < 0 || p.nsmYTop > p.depth || p.nsmYTop <= p.nsmYBottom
        error('cc19:input', 'Require 0 <= nsmYBottom < nsmYTop <= depth.');
    end
    % 3. Calculate angles, motion factors, and the crack endpoint.
    p.theta = p.thetaDeg * pi / 180;
    p.alpha = p.alphaDeg * pi / 180;
    p.kinematicDenominator = cos(p.theta) + p.slidingRatio * sin(p.theta);
    p.nsmProjection = (sin(p.theta + p.alpha) - p.slidingRatio * cos(p.theta + p.alpha)) / p.kinematicDenominator;
    if p.nsmProjection <= 0
        error('cc19:input', 'The assumed crack motion does not tension the NSM bars.');
    end
    p.crackTopX = p.crackOriginX + p.crackHeight / tan(p.theta);
    if p.crackTopX > p.shearSpan + 1e-8
        error('cc19:input', 'The critical crack leaves the modelled shear span.');
    end
    % 4. Generate bar endpoints, or use the supplied endpoint table.
    if isempty(p.nsmSegments)
        xb = p.nsmFirstX:p.nsmSpacing:p.shearSpan;
        dy = p.nsmYTop - p.nsmYBottom;
        segments = zeros(numel(xb), 4);
        for bar = 1:numel(xb)
            segments(bar, 1) = xb(bar);
            segments(bar, 2) = p.nsmYBottom;
            segments(bar, 3) = xb(bar) - dy / tan(p.alpha);
            segments(bar, 4) = p.nsmYTop;
        end
    else
        segments = p.nsmSegments;
        if ~isnumeric(segments) || ~isreal(segments) || size(segments, 2) ~= 4 || any(~isfinite(segments(:)))
            error('cc19:input', 'nsmSegments must be a finite n-by-4 matrix.');
        end
    end
    % 5. Intersect each bar with the crack and calculate anchor lengths.
    % bars columns: xCross,yCross,L_lower,L_upper,shape,actualAlphaRadians
    bars = zeros(0, 6);
    crack0 = [p.crackOriginX; 0];
    crackD = [p.crackTopX - p.crackOriginX; p.crackHeight];
    if p.nsmEnabled
        for i = 1:size(segments, 1)
            a = segments(i, 1:2)';
            b = segments(i, 3:4)';
            d = b - a;
            if norm(d) <= 0 || d(2) <= 0 || d(1) > 1e-8
                error('cc19:input', 'Each NSM segment must run from the bottom/right to the top/left.');
            end
            if any(a < [0; 0]) || any(a > [p.shearSpan; p.depth]) || b(2) < 0 || b(2) > p.depth
                error('cc19:input', 'NSM segment endpoints must be within beam boundaries.');
            end
            % Clip an automatically generated bar at x=0; custom bars must lie in the span.
            if b(1) < 0 && isempty(p.nsmSegments)
                b = a + (0 - a(1)) / d(1) * d;
                d = b - a;
            elseif b(1) < 0 || b(1) > p.shearSpan
                error('cc19:input', 'Custom NSM segment leaves the shear span.');
            end
            A = [d, -crackD];
            if abs(det(A)) < 1e-10
                continue
            end
            % Solve for the intersection fractions along the bar and crack.
            t = A \ (crack0 - a);
            if t(1) > 1e-8 && t(1) < 1 - 1e-8 && t(2) > 0 && t(2) < 1
                xy = a + t(1) * d;
                al = atan2(d(2), -d(1));
                proj = (sin(p.theta + al) - p.slidingRatio * cos(p.theta + al)) / p.kinematicDenominator;
                if proj <= 0
                    error('cc19:input', 'A custom bar is not opened in tension.');
                end
                row = size(bars, 1) + 1;
                bars(row, 1) = xy(1);
                bars(row, 2) = xy(2);
                bars(row, 3) = t(1) * norm(d);
                bars(row, 4) = (1 - t(1)) * norm(d);
                bars(row, 5) = (1 - xy(2) / p.crackHeight)^p.crackShapeExponent;
                bars(row, 6) = al;
            end
        end
    end
    p.bars = bars;
    p.nBars = size(bars, 1);
    p.generatedSegments = segments;
    % 6. Find the vertical stirrups crossing the crack.
    if isempty(p.stirrupX)
        sx = p.stirrupFirstX:p.stirrupSpacing:p.shearSpan;
    else
        sx = p.stirrupX;
    end
    if ~isnumeric(sx) || ~isreal(sx) || any(~isfinite(sx(:))) || any(sx(:) < 0) || any(sx(:) > p.shearSpan)
        error('cc19:input', 'Invalid stirrup coordinates.');
    end
    sy = (sx(:) - p.crackOriginX) * tan(p.theta);
    % Keep the original array formula to preserve floating-point results.
    shape = (1 - sy / p.crackHeight).^p.crackShapeExponent;
    p.steel = zeros(0, 3);
    for stirrup = 1:numel(sx)
        if p.stirrupArea == 0
            continue
        end
        if sy(stirrup) > 0 && sy(stirrup) < p.crackHeight
            row = size(p.steel, 1) + 1;
            p.steel(row, 1) = sx(stirrup);
            p.steel(row, 2) = sy(stirrup);
            p.steel(row, 3) = shape(stirrup);
        end
    end
    p.nSteel = size(p.steel, 1);
    % 7. Check snapshot cycles and output settings.
    if ~isnumeric(p.snapshotCycles) || ~isreal(p.snapshotCycles) || any(~isfinite(p.snapshotCycles(:))) ...
     || any(p.snapshotCycles(:) < 0) || any(p.snapshotCycles(:) ~= fix(p.snapshotCycles(:)))
        error('cc19:input', 'snapshotCycles must be nonnegative integers.');
    end
    p.snapshotCycles = unique([0 1 reshape(p.snapshotCycles, 1, []) p.Nmax]);
    savedCycles = [];
    for cycle = 1:numel(p.snapshotCycles)
        if p.snapshotCycles(cycle) <= p.Nmax
            savedCycles(end + 1) = p.snapshotCycles(cycle);
        end
    end
    p.snapshotCycles = savedCycles;
    if ~(ischar(p.outputDir) || (isstring(p.outputDir) && isscalar(p.outputDir))) || isempty(char(p.outputDir))
        error('cc19:input', 'outputDir must be a path.');
    end
    p.outputDir = char(p.outputDir);
    p.forceDefinition = 'Q is total actuator load; V=Q/2; T is one physical NSM bar axial force.';
end