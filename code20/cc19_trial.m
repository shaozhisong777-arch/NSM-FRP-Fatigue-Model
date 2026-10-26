function st = cc19_trial(p, q, memory, unload)
    % 截面试算。p为参数，memory为历史；输出st为当前响应及候选历史。
    % 给定裂缝竖向位移q，分别计算混凝土、箍筋、NSM的剪力贡献。
    % Vc经验闭合和钢筋传递长度沿用原模型，未实现论文2019式(7)的Green函数积分。
    if nargin < 4
        unload = false;
    end
    if ~isscalar(q) || ~isfinite(q) || q < 0
        error('cc19:trial', 'q must be nonnegative.');
    end
    k = cc19_curvature_integrals(p, q);
    next = memory;
    Vc = p.VcPeak * (1 - exp(-q / p.concreteRiseQ)) ...
     * (p.concreteResidualRatio + (1 - p.concreteResidualRatio) * exp(-k.wMax / p.concreteSofteningW)) ...
     * (1 - memory.concreteDamage);
    steelEps = q * p.steel(:, 3) / p.steelTransferLength;
    steelStress = min(p.Es * steelEps, p.fy);
    steelStress(memory.steelDamage >= 1) = 0;
    Vs = sum(p.stirrupArea * steelStress);
    T = zeros(p.nBars, 1);
    fields = cell(p.nBars, 1);
    failures = memory.barFailure;
    ok = true;
    maxResidual = 0;
    for j = 1:p.nBars
        if memory.failedFRP(j)
            continue
        end
        b = p.bars(j, :);
        al = b(6);
        projection = (sin(p.theta + al) - p.slidingRatio * cos(p.theta + al)) / p.kinematicDenominator;
        delta = max(0, q * b(5) * projection);
        tm1 = cc19_strength(p, memory.age{j, 1});
        tm2 = cc19_strength(p, memory.age{j, 2});
        a = cc19_hard(p, delta, b(3), b(4), memory.bondMax{j, 1}, memory.bondMax{j, 2}, tm1, tm2, unload);
        a.compatibilityResidual = abs(a.sides{1}.slip(1) + a.sides{2}.slip(1) - delta);
        fields{j} = a;
        ok = ok && a.ok && a.forceResidual <= p.forceTolerance;
        maxResidual = max(maxResidual, a.forceResidual);
        if ~unload
            next.bondMax{j, 1} = a.sides{1}.maxSlip;
            next.bondMax{j, 2} = a.sides{2}.maxSlip;
        end
        fail = '';
        if strcmp(a.status, 'full_debond')
            fail = 'full_anchorage_debond';
        elseif a.force >= p.Af * p.ffu
            fail = 'FRP_tensile_limit';
        elseif a.force >= p.coverCapacityPerBar
            fail = 'user_cover_capacity_limit';
        end
        if ~isempty(fail)
            next.failedFRP(j) = true;
            failures{j} = fail;
            fields{j}.force = 0;
            for s = 1:2
                fields{j}.sides{s}.tau(:) = 0;
                fields{j}.sides{s}.force(:) = 0;
                fields{j}.sides{s}.strain(:) = 0;
            end
        else
            T(j) = a.force;
        end
    end
    if p.nBars > 0
        Vn = p.nsmFaces * sum(T .* sin(p.bars(:, 6)));
    else
        Vn = 0;
    end
    next.barFailure = failures;
    st = struct('q', q, 'w', k.wMax, 'v', k.vMax, 'Vc', Vc, 'Vs', Vs, 'Vnsm', Vn, ...
                'V', Vc + Vs + Vn, 'barForce', T, 'steelStress', steelStress, 'steelStrain', steelEps, ...
                'fields', {fields}, 'memory', next, 'localOK', ok, 'localForceResidual', maxResidual, ...
                'forceResidual', NaN, 'unload', unload);
end
