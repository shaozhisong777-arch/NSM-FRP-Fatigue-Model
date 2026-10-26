function a = cc19_hard(p, delta, L1, L2, hist1, hist2, tm1, tm2, unload)
    % 双侧锚固求解。delta为两侧滑移之和；hist为最大滑移历史，tm为退化峰值。
    % dT/dx=-p_f*tau，du/dx=-T/(Ef*Af)。
    % T1=T2、s01+s02=delta

    if nargin < 9
        unload = false;
    end
    [x1, w1] = cc19_mesh(p, L1);
    [x2, w2] = cc19_mesh(p, L2);
    % 两段锚固共用裂缝节点；先装配FRP轴向刚度，再加入黏结刚度。
    n = p.nCells;
    m = 2 * n + 1;
    leftIndex = (n + 1:-1:1)';
    rightIndex = (n + 1:2 * n + 1)';
    hist1 = hist1(:);
    hist2 = hist2(:);
    tm1 = tm1(:);
    tm2 = tm2(:);
    if any([numel(hist1), numel(hist2), numel(tm1), numel(tm2)] ~= n + 1)
        error('cc19:anchor', 'Anchor arrays must contain nCells+1 nodes.');
    end
    axialStiffness = p.Ef * p.Af;
    elementLength = [flipud(diff(x1)); diff(x2)];
    elementStiffness = axialStiffness ./ elementLength;
    barStiffness = sparse(1:m, 1:m, [elementStiffness(1); elementStiffness(1:end - 1) + elementStiffness(2:end); elementStiffness(end)], m, m) ...
     + sparse(1:m - 1, 2:m, -elementStiffness, m, m) + sparse(2:m, 1:m - 1, -elementStiffness, m, m);
    u = delta * linspace(0, 1, m)';
    ok = false;
    h1 = hist1;
    h2 = hist2;
    % 第一步：用上一轮滑移更新割线刚度，再解线性方程组。
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
        [~, k1] = cc19_propagate(p, h1, tm1);
        [~, k2] = cc19_propagate(p, h2, tm2);
        c1 = p.perimeter * w1 .* k1;
        c2 = p.perimeter * w2 .* k2;
        diagK = accumarray([leftIndex; rightIndex], [c1; c2], [m 1]);
        rhs = accumarray(rightIndex, c2 * delta, [m 1]);
        A = barStiffness + spdiags(diagK, 0, m, m);
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

    % 固定点迭代失败时，保留Newton回退，不能把数值失败当成材料破坏。
    if ~ok
        [u, ok, extra] = cc19_anchor_newton(p, u, delta, barStiffness, leftIndex, rightIndex, w1, w2, hist1, hist2, tm1, tm2, unload);
        it = it + extra;
    end
    s1 = max(0, u(leftIndex));
    s2 = max(0, delta - u(rightIndex));
    if unload
        h1 = hist1;
        h2 = hist2;
    else
        h1 = max(hist1, s1);
        h2 = max(hist2, s2);
    end
    [~, k1] = cc19_propagate(p, h1, tm1);
    [~, k2] = cc19_propagate(p, h2, tm2);
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
    [~, k1] = cc19_propagate(p, m1, t1);
    [~, k2] = cc19_propagate(p, m2, t2);
    a1 = k1;
    a2 = k2;
    if ~unload
        active = s1 > h1;
        soft = active & s1 > p.deltaM & s1 <= p.deltaU;
        a1(soft) = -(t1(soft) - min(p.tauR, t1(soft))) / (p.deltaU - p.deltaM);
        a1(active & s1 > p.deltaU) = 0;
        active = s2 > h2;
        soft = active & s2 > p.deltaM & s2 <= p.deltaU;
        a2(soft) = -(t2(soft) - min(p.tauR, t2(soft))) / (p.deltaU - p.deltaM);
        a2(active & s2 > p.deltaU) = 0;
    end
    n = numel(u);
    R = barStiffness * u + accumarray(leftIndex, p.perimeter * w1 .* k1 .* s1, [n 1]) ...
      - accumarray(rightIndex, p.perimeter * w2 .* k2 .* s2, [n 1]);
    J = barStiffness + spdiags(accumarray([leftIndex; rightIndex], p.perimeter * [w1 .* a1; w2 .* a2], [n 1]), 0, n, n);
end

function a = cc19_anchor_output(p, x1, x2, s1, s2, h1, h2, tm1, tm2, F1, F2, it, ok, status)
    [~, k1, z1] = cc19_propagate(p, h1, tm1);
    [~, k2, z2] = cc19_propagate(p, h2, tm2);
    t1 = k1 .* s1;
    t2 = k2 .* s2;
    F = (F1 + F2) / 2;
    v1 = max(0, F1 - p.perimeter * cumtrapz(x1, t1));
    v2 = max(0, F2 - p.perimeter * cumtrapz(x2, t2));
    a = struct('force', F, 'leftForce', F1, 'rightForce', F2, 'forceResidual', abs(F1 - F2), ...
               'compatibilityResidual', 0, 'ok', ok, 'status', status, 'iterations', it, 'sides', {{}});
    a.sides = {struct('x', x1, 'slip', s1, 'maxSlip', h1, 'tau', t1, 'tauM', tm1, ...
                      'force', v1, 'strain', v1 / (p.Ef * p.Af), 'zone', z1), ...
               struct('x', x2, 'slip', s2, 'maxSlip', h2, 'tau', t2, 'tauM', tm2, ...
                    'force', v2, 'strain', v2 / (p.Ef * p.Af), 'zone', z2)};
end
