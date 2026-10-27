function a = anchorage(p, delta, L1, L2, hist1, hist2, tm1, tm2, unload)
    % Solve the two anchor sides. Their crack-end slips add up to delta.
    % hist1 and hist2 store maximum slips; tm1 and tm2 store bond peaks.
    % Equilibrium: dT/dx = -perimeter*tau; du/dx = -T/(Ef*Af).
    % The two sides must carry the same crack-end force.

    if nargin < 9
        unload = false;
    end
    [x1, w1] = anchor_mesh(p, L1);
    [x2, w2] = anchor_mesh(p, L2);
    % 1. Number the nodes. Both sides share the crack node.
    n = p.nCells;
    m = 2 * n + 1;
    leftIndex = zeros(n + 1, 1);
    rightIndex = zeros(n + 1, 1);
    for node = 1:n + 1
        leftIndex(node) = n + 2 - node;
        rightIndex(node) = n + node;
    end
    hist1 = hist1(:);
    hist2 = hist2(:);
    tm1 = tm1(:);
    tm2 = tm2(:);
    if numel(hist1) ~= n + 1 || numel(hist2) ~= n + 1 || ...
            numel(tm1) ~= n + 1 || numel(tm2) ~= n + 1
        error('cc19:anchor', 'Anchor arrays must contain nCells+1 nodes.');
    end

    % 2. Add each bar element to the global stiffness matrix.
    axialStiffness = p.Ef * p.Af;
    elementLength = zeros(2 * n, 1);
    for element = 1:n
        elementLength(element) = x1(n + 2 - element) - x1(n + 1 - element);
        elementLength(n + element) = x2(element + 1) - x2(element);
    end
    barStiffness = sparse(m, m);
    for element = 1:2 * n
        stiffness = axialStiffness / elementLength(element);
        first = element;
        second = element + 1;
        barStiffness(first, first) = barStiffness(first, first) + stiffness;
        barStiffness(second, second) = barStiffness(second, second) + stiffness;
        barStiffness(first, second) = -stiffness;
        barStiffness(second, first) = -stiffness;
    end
    u = delta * linspace(0, 1, m)';
    ok = false;
    h1 = hist1;
    h2 = hist2;
    % 3. Update bond stiffness and solve for displacement repeatedly.
    for it = 1:p.localMaxIterations
        s1 = max(0, u(leftIndex));
        s2 = max(0, delta - u(rightIndex));
        if unload
            h1 = hist1;
            h2 = hist2;
        else
            h1 = max(hist1, s1);
            h2 = max(hist2, s2);
        end
        [~, k1] = bond(p, h1, tm1);
        [~, k2] = bond(p, h2, tm2);
        c1 = p.perimeter * w1 .* k1;
        c2 = p.perimeter * w2 .* k2;
        bondDiagonal = zeros(m, 1);
        rhs = zeros(m, 1);
        for node = 1:n + 1
            left = leftIndex(node);
            right = rightIndex(node);
            bondDiagonal(left) = bondDiagonal(left) + c1(node);
            bondDiagonal(right) = bondDiagonal(right) + c2(node);
            rhs(right) = rhs(right) + c2(node) * delta;
        end
        A = barStiffness;
        for node = 1:m
            A(node, node) = A(node, node) + bondDiagonal(node);
        end
        if all(c1 == 0) || all(c2 == 0)
            a = cc19_anchor_output(p, x1, x2, s1, s2, h1, h2, tm1, tm2, 0, 0, it, true, 'full_debond');
            return
        end
        nextU = A \ rhs;
        slipError = max(abs(nextU - u));
        if slipError <= p.localTolerance * max(1, delta)
            u = nextU;
            ok = true;
            break
        end
        if it < 3
            u = nextU;
        else
            u = 0.6 * nextU + 0.4 * u;
        end
    end

    % 4. Try Newton iteration if the first iteration did not converge.
    % A numerical failure must not be treated as material failure.
    if ~ok
        [u, ok, extra] = cc19_anchor_newton(p, u, delta, barStiffness, leftIndex, rightIndex, w1, w2, hist1, hist2, tm1, tm2, unload);
        it = it + extra;
    end
    s1 = zeros(n + 1, 1);
    s2 = zeros(n + 1, 1);
    for node = 1:n + 1
        s1(node) = max(0, u(leftIndex(node)));
        s2(node) = max(0, delta - u(rightIndex(node)));
    end
    if unload
        h1 = hist1;
        h2 = hist2;
    else
        h1 = max(hist1, s1);
        h2 = max(hist2, s2);
    end
    [~, k1] = bond(p, h1, tm1);
    [~, k2] = bond(p, h2, tm2);
    t1 = k1 .* s1;
    t2 = k2 .* s2;
    F1 = p.perimeter * sum(w1 .* t1);
    F2 = p.perimeter * sum(w2 .* t2);
    status = 'balanced';
    if ~ok
        status = 'local_iteration_not_converged';
    end
    if ~unload && (h1(end) >= p.deltaU || h2(end) >= p.deltaU)
        status = 'full_debond';
        F1 = 0;
        F2 = 0;
    end
    a = cc19_anchor_output(p, x1, x2, s1, s2, h1, h2, tm1, tm2, F1, F2, it, ok, status);
end

% Newton fallback: try four initial guesses, then shorten each step if needed.
function [u, ok, total] = cc19_anchor_newton(p, u0, d, barStiffness, leftIndex, rightIndex, w1, w2, h1, h2, t1, t2, unload)
    ok = false;
    total = 0;
    n = numel(u0);
    starts = [u0, d * 0.5 * ones(n, 1), d * 0.15 * ones(n, 1), d * 0.85 * ones(n, 1)];
    best = Inf;
    bestU = u0;
    for seed = 1:size(starts, 2)
        u = starts(:, seed);
        for iter = 1:80
            total = total + 1;
            [R, J] = cc19_anchor_residual(p, u, d, barStiffness, leftIndex, rightIndex, w1, w2, h1, h2, t1, t2, unload);
            nr = norm(R, Inf);
            if nr < best
                best = nr;
                bestU = u;
            end
            if nr < min(1e-5, p.forceTolerance / 100)
                ok = true;
                return
            end
            step = J \ R;
            accepted = false;
            if any(~isfinite(step))
                break
            end
            scale = 1;
            for ls = 1:25
                candidate = min(d, max(0, u - scale * step));
                rr = cc19_anchor_residual(p, candidate, d, barStiffness, leftIndex, rightIndex, w1, w2, h1, h2, t1, t2, unload);
                if norm(rr, Inf) < nr * (1 - 1e-5 * scale)
                    u = candidate;
                    accepted = true;
                    break
                end
                scale = scale / 2;
            end
            if ~accepted
                break
            end
        end
    end
    u = bestU;
end

% R is the nodal force imbalance; J is its tangent stiffness matrix.
function [R, J] = cc19_anchor_residual(p, u, d, barStiffness, leftIndex, rightIndex, w1, w2, h1, h2, t1, t2, unload)
    s1 = max(0, u(leftIndex));
    s2 = max(0, d - u(rightIndex));
    if unload
        m1 = h1;
        m2 = h2;
    else
        m1 = max(h1, s1);
        m2 = max(h2, s2);
    end
    [~, k1] = bond(p, m1, t1);
    [~, k2] = bond(p, m2, t2);
    a1 = k1;
    a2 = k2;
    % Use the envelope tangent only where the historical slip is exceeded.
    for node = 1:numel(s1)
        if ~unload
            if s1(node) > h1(node)
                if s1(node) > p.deltaU
                    a1(node) = 0;
                elseif s1(node) > p.deltaM
                    a1(node) = -(t1(node) - min(p.tauR, t1(node))) / (p.deltaU - p.deltaM);
                end
            end
            if s2(node) > h2(node)
                if s2(node) > p.deltaU
                    a2(node) = 0;
                elseif s2(node) > p.deltaM
                    a2(node) = -(t2(node) - min(p.tauR, t2(node))) / (p.deltaU - p.deltaM);
                end
            end
        end
    end
    nodeCount = numel(u);
    leftBondForce = zeros(nodeCount, 1);
    rightBondForce = zeros(nodeCount, 1);
    bondDiagonal = zeros(nodeCount, 1);
    % Add bond forces and tangent stiffness one node at a time.
    for node = 1:numel(s1)
        left = leftIndex(node);
        right = rightIndex(node);
        leftBondForce(left) = leftBondForce(left) + p.perimeter * w1(node) * k1(node) * s1(node);
        rightBondForce(right) = rightBondForce(right) + p.perimeter * w2(node) * k2(node) * s2(node);
        bondDiagonal(left) = bondDiagonal(left) + p.perimeter * (w1(node) * a1(node));
        bondDiagonal(right) = bondDiagonal(right) + p.perimeter * (w2(node) * a2(node));
    end
    R = barStiffness * u + leftBondForce - rightBondForce;
    J = barStiffness;
    for node = 1:nodeCount
        J(node, node) = J(node, node) + bondDiagonal(node);
    end
end

function a = cc19_anchor_output(p, x1, x2, s1, s2, h1, h2, tm1, tm2, F1, F2, it, ok, status)
    [~, k1, z1] = bond(p, h1, tm1);
    [~, k2, z2] = bond(p, h2, tm2);
    t1 = k1 .* s1;
    t2 = k2 .* s2;
    F = (F1 + F2) / 2;
    v1 = max(0, F1 - p.perimeter * cumtrapz(x1, t1));
    v2 = max(0, F2 - p.perimeter * cumtrapz(x2, t2));
    % Store the total result first, followed by each side's nodal fields.
    a.force = F;
    a.leftForce = F1;
    a.rightForce = F2;
    a.forceResidual = abs(F1 - F2);
    a.compatibilityResidual = 0;
    a.ok = ok;
    a.status = status;
    a.iterations = it;
    a.sides = cell(1, 2);
    leftSide.x = x1;
    leftSide.slip = s1;
    leftSide.maxSlip = h1;
    leftSide.tau = t1;
    leftSide.tauM = tm1;
    leftSide.force = v1;
    leftSide.strain = v1 / (p.Ef * p.Af);
    leftSide.zone = z1;
    rightSide.x = x2;
    rightSide.slip = s2;
    rightSide.maxSlip = h2;
    rightSide.tau = t2;
    rightSide.tauM = tm2;
    rightSide.force = v2;
    rightSide.strain = v2 / (p.Ef * p.Af);
    rightSide.zone = z2;
    a.sides{1} = leftSide;
    a.sides{2} = rightSide;
end
