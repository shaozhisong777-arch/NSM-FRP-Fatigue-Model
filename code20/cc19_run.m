function out = cc19_run(p)
    % 疲劳主循环。只在重新平衡成功后提交候选损伤；N表示整梁循环数。
    % 疲劳主循环：冻结损伤求最大/最小荷载平衡 -> 更新局部计数和可选Miner损伤。
    % 全局V随NSM黏结退化而重分配；单根筋损失后继续寻找整梁平衡。
    p = cc19_validate(p);
    memory = cc19_new_memory(p);
    out = struct('parameters', p, 'status', 'running', 'lastCycle', 0, 'failureCycle', NaN, ...
                 'failureBracket', [NaN NaN], 'history', zeros(0, 16), 'snapshots', struct([]), ...
                 'lastState', [], 'lastLowState', [], 'memory', memory, ...
                 'calibrationStatus', p.calibrationStatus, 'initialCapacity', [], ...
                 'lastInfo', [], 'failureCapacity', NaN);
    out.historyColumns = {'N', 'qMax_mm', 'qMin_mm', 'wMax_mm', 'slidingMax_mm', ...
                          'Vmax_N', 'Vc_N', 'Vs_N', 'Vnsm_N', 'beamResidual_N', 'anchorResidual_N', ...
                          'failedNSMlines', 'maxSteelStress_MPa', 'maxSteelMinerDamage', 'concreteMinerDamage', 'cycleBlock'};
    if p.computeCapacity
        out.initialCapacity = cc19_critical(p, memory);
    else
        out.initialCapacity = struct('curve', zeros(0, 5), ...
                                     'columns', {{'q_mm', 'V_N', 'Vc_N', 'Vs_N', 'Vnsm_N'}}, 'status', 'not_requested');
    end
    [peak, info] = cc19_state(p, memory, p.Qmax / 2, 0, false);
    out.lastInfo = info;
    if ~info.ok
        out.status = ['initial_' info.status];
        out.failureCapacity = info.capacity;
        if strcmp(info.status, 'no_equilibrium_in_model_domain')
            out.failureCycle = 0;
            out.failureBracket = [0 0];
        end
        if p.verbose
            fprintf('%s: %s\n', p.kind, out.status);
        end
        return
    end
    memory = peak.memory;
    [low, lowInfo] = cc19_state(p, memory, p.Qmin / 2, peak.q, true);
    if ~lowInfo.ok
        out.status = ['minimum_load_' lowInfo.status];
        out.lastInfo = lowInfo;
        return
    end
    N = 0;
    out.history = cc19_row(N, peak, low, memory, 0);
    out.snapshots = cc19_snapshot(p, N, peak, low, memory);
    % 每个循环块：识别活跃节点 -> 提议损伤 -> 重新平衡 -> 成功后提交。
    while N < p.Nmax
        [activeNodes, ~] = cc19_active(p, peak, low, memory);
        % 用普通for循环检查，不使用初学者不熟悉的cellfun和匿名函数。
        hasActiveNodes = false;
        for bar = 1:p.nBars
            for side = 1:2
                if any(activeNodes{bar, side})
                    hasActiveNodes = true;
                end
            end
        end
        if ~hasActiveNodes && ~isfinite(p.steelSNrefCycles) && ~isfinite(p.concreteSNrefCycles)
            for n = p.snapshotCycles(p.snapshotCycles > N)
                out.history(end + 1, :) = cc19_row(n, peak, low, memory, n - N);
                out.snapshots(end + 1) = cc19_snapshot(p, n, peak, low, memory);
                N = n;
            end
            out.status = 'runout_no_active_degradation';
            break
        end
        remainingSnapshots = p.snapshotCycles(p.snapshotCycles > N);
        target = remainingSnapshots(1); % 下一次需要保存完整场的循环数
        cycleBlock = min([p.cycleStep, p.Nmax - N, target - N]);
        while true
            proposed = memory;
            for j = 1:p.nBars
                for s = 1:2
                    proposed.activated{j, s} = memory.activated{j, s} | activeNodes{j, s};
                    proposed.age{j, s}(activeNodes{j, s}) = memory.age{j, s}(activeNodes{j, s}) + cycleBlock;
                end
            end
            % 可选钢筋S-N：使用实际交点的峰谷应力范围；默认关闭。
            if isfinite(p.steelSNrefCycles) && p.Qmax > p.Qmin
                range = max(0, peak.steelStress - low.steelStress);
                life = p.steelSNrefCycles * (p.steelSNrefStress ./ max(range, realmin)).^p.steelSNexponent;
                proposed.steelDamage = min(1, memory.steelDamage + cycleBlock ./ life);
            end
            % 可选混凝土S-N：使用等效截面剪应力范围；默认关闭。
            if isfinite(p.concreteSNrefCycles) && p.Qmax > p.Qmin
                qq = linspace(low.q, peak.q, 41);
                ww = qq / p.kinematicDenominator;
                vc = p.VcPeak * (1 - exp(-qq / p.concreteRiseQ)) ...
                 .* (p.concreteResidualRatio + (1 - p.concreteResidualRatio) * exp(-ww / p.concreteSofteningW)) ...
                 * (1 - memory.concreteDamage);
                range = (max(vc) - min(vc)) / (p.width * p.ds);
                life = p.concreteSNrefCycles * (p.concreteSNrefStress / max(range, realmin))^p.concreteSNexponent;
                proposed.concreteDamage = min(1, memory.concreteDamage + cycleBlock / life);
            end
            [next, nextInfo] = cc19_state(p, proposed, p.Qmax / 2, peak.q, false);
            openingTooFast = nextInfo.ok && next.q - peak.q > p.maxOpeningStep;
            if cycleBlock > 1 && (~nextInfo.ok || openingTooFast)
                cycleBlock = max(1, floor(cycleBlock / 2));
                continue
            end
            break
        end
        out.lastInfo = nextInfo;
        if ~nextInfo.ok
            out.status = nextInfo.status;
            out.failureCapacity = nextInfo.capacity;
            if strcmp(nextInfo.status, 'no_equilibrium_in_model_domain') || strcmp(nextInfo.status, 'user_concrete_strut_limit') || strcmp(nextInfo.status, 'user_flexural_limit')
                out.failureCycle = N + cycleBlock;
                out.failureBracket = [N N + cycleBlock];
            end
            break
        end
        nextMemory = next.memory;
        [nextLow, nextLowInfo] = cc19_state(p, nextMemory, p.Qmin / 2, next.q, true);
        if ~nextLowInfo.ok
            out.status = ['minimum_load_' nextLowInfo.status];
            out.lastInfo = nextLowInfo;
            break
        end
        N = N + cycleBlock;
        peak = next;
        low = nextLow;
        memory = nextMemory;
        out.history(end + 1, :) = cc19_row(N, peak, low, memory, cycleBlock);
        % 长算例每约10%输出一次进度，便于区分“仍在算”和“已经卡住”。
        printInterval = max(1, round(p.Nmax / 10));
        if p.verbose && (mod(N, printInterval) == 0 || N == p.Nmax)
            fprintf('N=%g/%g, q=%.6g mm, force residual=%.3g N\n', ...
                N, p.Nmax, peak.q, peak.forceResidual);
        end
        if any(p.snapshotCycles == N)
            out.snapshots(end + 1) = cc19_snapshot(p, N, peak, low, memory);
        end
    end
    if strcmp(out.status, 'running')
        out.status = 'runout_at_Nmax';
    end
    out.lastCycle = N;
    out.lastState = peak;
    out.lastLowState = low;
    out.memory = memory;
    if out.snapshots(end).N ~= N
        out.snapshots(end + 1) = cc19_snapshot(p, N, peak, low, memory);
    end
    if p.verbose
        fprintf('%s NSM shear: %s; last balanced cycle=%g\n', p.kind, out.status, N);
        fprintf('V=%.6g N = Vc %.6g + Vs %.6g + Vnsm %.6g; q=%.6g mm\n', peak.V, peak.Vc, peak.Vs, peak.Vnsm, peak.q);
        fprintf('Crossed NSM lines per face=%d, faces=%d; calibration=%s\n', p.nBars, p.nsmFaces, p.calibrationStatus);
        if isfinite(out.failureCycle)
            fprintf('Model failure bracket: [%g,%g]\n', out.failureBracket);
        end
    end
end

function m = cc19_new_memory(p)
    m = struct('bondMax', {cell(p.nBars, 2)}, 'age', {cell(p.nBars, 2)}, ...
               'activated', {cell(p.nBars, 2)}, 'failedFRP', false(p.nBars, 1), ...
               'barFailure', {repmat({''}, p.nBars, 1)}, 'steelDamage', zeros(p.nSteel, 1), 'concreteDamage', 0);
    for j = 1:p.nBars
        for s = 1:2
            m.bondMax{j, s} = zeros(p.nCells + 1, 1);
            m.age{j, s} = zeros(p.nCells + 1, 1);
            m.activated{j, s} = false(p.nCells + 1, 1);
        end
    end
end

function row = cc19_row(N, peak, low, m, cycleBlock)
    row = [N, peak.q, low.q, peak.w, peak.v, peak.V, peak.Vc, peak.Vs, peak.Vnsm, ...
           peak.forceResidual, peak.localForceResidual, sum(m.failedFRP), max([0; peak.steelStress]), ...
           max([0; m.steelDamage]), m.concreteDamage, cycleBlock];
end

function z = cc19_snapshot(p, N, peak, low, m)
    z = struct('N', N, 'peak', peak, 'minimum', low, 'field', cc19_sample(p, peak, m), ...
               'memory', m, 'reference', cc19_paper_interpolation(p, peak));
end
