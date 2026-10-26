function report = verify_2019()
    % 独立数值验证。检查解析解、峰谷平衡、激活退化、单筋退出和S-N接口。
    % 数值和机制验证，不等于抗剪疲劳试验校准。可在MATLAB或GNU Octave运行。
    p = cc19_validate(cc19_parameters('strip'));
    assert(p.nBars > 0 && p.nSteel > 0);
    % 双侧有限锚固的独立线弹性解析解，包含短侧主导和两端零轴力边界。
    pa = p;
    pa.nCells = 100;
    z = zeros(pa.nCells + 1, 1);
    tm = pa.tauM0 * ones(size(z));
    d = 0.02;
    L1 = 120;
    L2 = 260;
    a = cc19_hard(pa, d, L1, L2, z, z, tm, tm, false);
    lambda = sqrt(pa.perimeter * pa.tauM0 / (pa.deltaM * pa.Ef * pa.Af));
    K1 = pa.Ef * pa.Af * lambda * tanh(lambda * L1);
    K2 = pa.Ef * pa.Af * lambda * tanh(lambda * L2);
    exact = d / (1 / K1 + 1 / K2);
    relative = abs(a.force / exact - 1);
    assert(a.ok && relative < 0.002);
    assert(a.forceResidual < 0.01);
    assert(abs(a.sides{1}.slip(1) + a.sides{2}.slip(1) - d) < 1e-10);
    assert(max([a.sides{1}.force(end), a.sides{2}.force(end)]) < 1e-5);
    b = cc19_hard(pa, d, 40, L2, z, z, tm, tm, false);
    assert(b.force < a.force && b.sides{1}.slip(1) > b.sides{2}.slip(1));
    weakened = cc19_hard(pa, d, L1, L2, z, z, 0.5 * tm, tm, false);
    assert(weakened.force < a.force);
    % 疲劳论文式(2)：未激活/首循环保持初值，极长局部龄期峰值归零。
    ns = [0 1 10 1e12];
    t = cc19_strength(p, ns);
    assert(t(1) == p.tauM0 && t(2) == p.tauM0 && all(t >= 0) && t(end) == 0);
    assert(abs(t(3) - max(0, p.tauM0 * (1 - p.bondFatigueK))) < 1e-12);
    % 新增论文核对：杆/条不同系数，相同75%阈值，峰值归零后不得保留假强度。
    rodParameters = cc19_parameters('rod');
    assert(p.bondFatigueK == 0.1985 && rodParameters.bondFatigueK == 0.1965);
    assert(p.activationFraction == 0.75 && rodParameters.activationFraction == 0.75);
    slips = linspace(0, 2, 101)';
    [smallStress, ~] = cc19_propagate(p, slips, 0.5);
    [zeroStress, ~] = cc19_propagate(p, slips, 0);
    assert(all(smallStress <= 0.5) && all(smallStress >= 0));
    assert(all(zeroStress == 0));
    % 与未加固对照在同一可承受荷载下比较，NSM的力确实参与全梁平衡。
    o = struct('Qmax', 110000, 'Qmin', 20000, 'Nmax', 1, 'makePlots', false, ...
               'exportResults', false, 'verbose', false, 'computeCapacity', false, 'nCells', 16, 'scanPoints', 41);
    strengthened = ff19('strip', o);
    o.nsmEnabled = false;
    control = ff19('strip', o);
    assert(~isempty(strengthened.lastState) && ~isempty(control.lastState));
    assert(strengthened.lastState.Vnsm > 0 && control.lastState.Vnsm == 0);
    assert(strengthened.lastState.q < control.lastState.q);
    assert(max(strengthened.lastState.steelStress) < max(control.lastState.steelStress));
    globalError = max(strengthened.history(:, 10));
    assert(globalError < p.forceTolerance * 1.01);
    % 相同最大最小荷载没有循环，不得仅因N增加而产生疲劳退化。
    steady = o;
    steady.nsmEnabled = true;
    steady.Qmin = steady.Qmax;
    steady.Nmax = 50;
    steady.activationFraction = 0.001;
    noCycle = ff19('strip', steady);
    for j = 1:noCycle.parameters.nBars
        for s = 1:2
            assert(all(noCycle.memory.age{j, s} == 0));
        end
    end
    % 人为降低触发阈值的机制测试：保证确有界面退化和剪力重分配。
    fat = o;
    fat.nsmEnabled = true;
    fat.Qmax = 165000;
    fat.Nmax = 40;
    fat.activationFraction = 0.10;
    fatigue = ff19('strip', fat);
    assert(~isempty(fatigue.lastState));
    activeCount = 0;
    untouchedCount = 0;
    for j = 1:fatigue.parameters.nBars
        for s = 1:2
            activeCount = activeCount + sum(fatigue.memory.age{j, s} > 1);
            untouchedCount = untouchedCount + sum(fatigue.memory.age{j, s} == 0);
        end
    end
    assert(activeCount > 0 && untouchedCount > 0);
    assert(fatigue.lastState.q > fatigue.history(1, 2));
    assert(all(diff(fatigue.history(:, 2)) >= -1e-7));
    assert(max(fatigue.history(:, 10)) < p.forceTolerance * 1.01);
    % 入口和分模块必须一致，且错误不能伪装成物理失效。
    pp = cc19_parameters('strip');
    names = fieldnames(fat);
    for i = 1:numel(names)
        pp.(names{i}) = fat.(names{i});
    end
    modular = cc19_run(pp);
    assert(isequal(size(fatigue.history), size(modular.history)));
    assert(max(abs(fatigue.history(:) - modular.history(:))) < 1e-9);
    % 单根完全脱黏并不等于整梁破坏；其余NSM和RC仍须重新平衡。
    loss = cc19_trial(strengthened.parameters, 2.5, strengthened.memory, false);
    assert(sum(loss.memory.failedFRP) == 1 && loss.localOK);
    [remaining, remainingInfo] = cc19_state(strengthened.parameters, loss.memory, 55000, 0, false);
    assert(remainingInfo.ok && remaining.Vnsm > 0 && sum(remaining.memory.failedFRP) == 1);
    assert(remaining.forceResidual < p.forceTolerance);
    % 可选Miner接口用人为极低寿命参数验证，绝不作为材料标定数据。
    sn = o;
    sn.nsmEnabled = true;
    sn.Nmax = 2;
    sn.steelSNrefCycles = 1;
    sn.steelSNrefStress = 10;
    sn.steelSNexponent = 3;
    steelSN = ff19('strip', sn);
    assert(all(steelSN.memory.steelDamage == 1));
    sn = o;
    sn.nsmEnabled = true;
    sn.Nmax = 2;
    sn.concreteSNrefCycles = 1;
    sn.concreteSNrefStress = 0.01;
    sn.concreteSNexponent = 3;
    concreteSN = ff19('strip', sn);
    assert(concreteSN.memory.concreteDamage == 1);
    bad = pp;
    bad.thetaDeg = 0;
    rejected = false;
    try
        cc19_validate(bad);
    catch
        rejected = true;
    end
    assert(rejected);
    report = struct('elasticAnchorRelativeError', relative, 'anchorForceMismatch_N', a.forceResidual, ...
                    'maxGlobalEquilibriumResidual_N', max([globalError; fatigue.history(:, 10)]), ...
                    'strengthenedCrackJump_mm', strengthened.lastState.q, ...
                    'controlCrackJump_mm', control.lastState.q, 'fatigueActiveNodes', activeCount, ...
                    'fatigueUnactivatedNodes', untouchedCount, 'zeroLoadRangeNoFatigue', true, ...
                    'modularEntryMatch', true, 'singleBarLossBeamContinues', true, ...
                    'optionalMinerInterfacesChecked', true, 'experimentalCalibration', false);
    disp(report);
    fprintf('NSM shear equilibrium verification passed in this runtime.\n');
end
