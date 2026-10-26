function out = fatigue_calculate(p)
% FATIGUE_CALCULATE Run the original critical-crack shear-fatigue workflow.
% p: parameters. memory: irreversible history. peak/low: balanced load states.
%
% Sources and limitations:
% [F] Chen et al. (2019), Int. J. Fatigue 126, 174-187,
%     DOI 10.1016/j.ijfatigue.2019.04.039, Eq. (2) and Section 2.8.
%     Local bond aging is evaluated through cc19_active/cc19_strength.
% [S] Chen and Cheng (2019), DOI 10.1061/(ASCE)CC.1943-5614.0000953.
%     Two-sided anchorage is related to Eqs. (9d), (11), in external solvers.
% [A] Transferring the flexural bond-fatigue law to shear is an adaptation.
%     Optional steel/concrete S-N and Miner rules are extra model assumptions.
%     The empirical Vc and prescribed crack shape do not implement [S] Eq. (7).
% [N] Cycle blocks, step halving, saved rows and snapshots are numerical steps.
% This rewrite preserves the uploaded algorithm, output fields and defaults.

%% 1. Check parameters and prepare empty history.
p = cc19_validate(p);
memory = create_memory(p);
out = create_output(p, memory);

if p.computeCapacity
    out.initialCapacity = cc19_critical(p, memory);
end

%% 2. Solve the first maximum-load and minimum-load states.
% Q is total load in symmetric four-point loading; shear-span force is Q/2.
[peak, peakInfo] = cc19_state(p, memory, p.Qmax / 2, 0, false);
out.lastInfo = peakInfo;
if ~peakInfo.ok
    out.status = ['initial_' peakInfo.status];
    out.failureCapacity = peakInfo.capacity;
    if strcmp(peakInfo.status, 'no_equilibrium_in_model_domain')
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
out.history = history_row(N, peak, low, memory, 0);
out.snapshots = make_snapshot(p, N, peak, low, memory);

%% 3. Advance cycles until Nmax or a diagnosed stop.
while N < p.Nmax
    % [F/A] Activation checks the slip threshold AND a nonzero cyclic range.
    [activeNodes, ~] = cc19_active(p, peak, low, memory);
    hasActiveNodes = false;
    for bar = 1:p.nBars
        for side = 1:2
            for node = 1:p.nCells + 1
                if activeNodes{bar, side}(node)
                    hasActiveNodes = true;
                end
            end
        end
    end

    % [N] Nothing can evolve if bond aging and both optional S-N rules are off.
    steelFatigueOn = isfinite(p.steelSNrefCycles);
    concreteFatigueOn = isfinite(p.concreteSNrefCycles);
    if ~hasActiveNodes && ~steelFatigueOn && ~concreteFatigueOn
        for i = 1:numel(p.snapshotCycles)
            savedCycle = p.snapshotCycles(i);
            if savedCycle > N
                cycleBlock = savedCycle - N;
                out.history(end + 1, :) = history_row(savedCycle, peak, low, memory, cycleBlock);
                out.snapshots(end + 1) = make_snapshot(p, savedCycle, peak, low, memory);
                N = savedCycle;
            end
        end
        out.status = 'runout_no_active_degradation';
        break
    end

    % [N] Do not step past the next requested snapshot or the final cycle.
    nextSavedCycle = p.Nmax;
    for i = 1:numel(p.snapshotCycles)
        if p.snapshotCycles(i) > N
            nextSavedCycle = p.snapshotCycles(i);
            break
        end
    end
    cycleBlock = min(p.cycleStep, p.Nmax - N);
    cycleBlock = min(cycleBlock, nextSavedCycle - N);

    %% 4. Propose damage, then test equilibrium before accepting it.
    retryBlock = true;
    while retryBlock
        proposed = update_memory(p, memory, activeNodes, peak, low, cycleBlock);
        [nextPeak, nextInfo] = cc19_state(p, proposed, p.Qmax / 2, peak.q, false);

        openingTooFast = false;
        if nextInfo.ok
            if nextPeak.q - peak.q > p.maxOpeningStep
                openingTooFast = true;
            end
        end

        % [N] A smaller cycle block improves resolution; it is not a material law.
        retryBlock = false;
        if cycleBlock > 1
            if ~nextInfo.ok || openingTooFast
                cycleBlock = floor(cycleBlock / 2);
                if cycleBlock < 1
                    cycleBlock = 1;
                end
                retryBlock = true;
            end
        end
    end

    out.lastInfo = nextInfo;
    if ~nextInfo.ok
        out.status = nextInfo.status;
        out.failureCapacity = nextInfo.capacity;
        modelLimitReached = strcmp(nextInfo.status, 'no_equilibrium_in_model_domain');
        strutLimitReached = strcmp(nextInfo.status, 'user_concrete_strut_limit');
        momentLimitReached = strcmp(nextInfo.status, 'user_flexural_limit');
        if modelLimitReached || strutLimitReached || momentLimitReached
            out.failureCycle = N + cycleBlock;
            out.failureBracket = [N N + cycleBlock];
        end
        break
    end

    nextMemory = nextPeak.memory;
    [nextLow, nextLowInfo] = cc19_state(p, nextMemory, p.Qmin / 2, nextPeak.q, true);
    if ~nextLowInfo.ok
        out.status = ['minimum_load_' nextLowInfo.status];
        out.lastInfo = nextLowInfo;
        break
    end

    %% 5. Accept the block only after BOTH load states have converged.
    N = N + cycleBlock;
    peak = nextPeak;
    low = nextLow;
    memory = nextMemory;
    out.history(end + 1, :) = history_row(N, peak, low, memory, cycleBlock);

    printInterval = max(1, round(p.Nmax / 10));
    if p.verbose && (mod(N, printInterval) == 0 || N == p.Nmax)
        fprintf('N=%g/%g, q=%.6g mm, force residual=%.3g N\n', ...
                N, p.Nmax, peak.q, peak.forceResidual);
    end
    for i = 1:numel(p.snapshotCycles)
        if p.snapshotCycles(i) == N
            out.snapshots(end + 1) = make_snapshot(p, N, peak, low, memory);
            break
        end
    end
end

%% 6. Return the last fully balanced state and the diagnosed stop status.
if strcmp(out.status, 'running')
    out.status = 'runout_at_Nmax';
end
out.lastCycle = N;
out.lastState = peak;
out.lastLowState = low;
out.memory = memory;
if out.snapshots(end).N ~= N
    out.snapshots(end + 1) = make_snapshot(p, N, peak, low, memory);
end
if p.verbose
    fprintf('%s NSM shear: %s; last balanced cycle=%g\n', p.kind, out.status, N);
    fprintf('V=%.6g N = Vc %.6g + Vs %.6g + Vnsm %.6g; q=%.6g mm\n', ...
            peak.V, peak.Vc, peak.Vs, peak.Vnsm, peak.q);
    fprintf('Crossed NSM lines per face=%d, faces=%d; calibration=%s\n', ...
            p.nBars, p.nsmFaces, p.calibrationStatus);
    if isfinite(out.failureCycle)
        fprintf('Model failure bracket: [%g,%g]\n', out.failureBracket);
    end
end
end

function memory = create_memory(p)
% Each cell stores one column of nodes for one bar and one anchorage side.
memory.bondMax = cell(p.nBars, 2);
memory.age = cell(p.nBars, 2);
memory.activated = cell(p.nBars, 2);
memory.failedFRP = false(p.nBars, 1);
memory.barFailure = cell(p.nBars, 1);
memory.steelDamage = zeros(p.nSteel, 1);
memory.concreteDamage = 0;
for bar = 1:p.nBars
    memory.barFailure{bar} = '';
    for side = 1:2
        memory.bondMax{bar, side} = zeros(p.nCells + 1, 1);
        memory.age{bar, side} = zeros(p.nCells + 1, 1);
        memory.activated{bar, side} = false(p.nCells + 1, 1);
    end
end
end

function out = create_output(p, memory)
% Assign one field at a time instead of a long nested struct constructor.
out.parameters = p;
out.status = 'running';
out.lastCycle = 0;
out.failureCycle = NaN;
out.failureBracket = [NaN NaN];
out.history = zeros(0, 16);
out.snapshots = struct([]);
out.lastState = [];
out.lastLowState = [];
out.memory = memory;
out.calibrationStatus = p.calibrationStatus;
out.initialCapacity.curve = zeros(0, 5);
out.initialCapacity.columns = {'q_mm', 'V_N', 'Vc_N', 'Vs_N', 'Vnsm_N'};
out.initialCapacity.status = 'not_requested';
out.lastInfo = [];
out.failureCapacity = NaN;
out.historyColumns = {'N', 'qMax_mm', 'qMin_mm', 'wMax_mm', 'slidingMax_mm', ...
    'Vmax_N', 'Vc_N', 'Vs_N', 'Vnsm_N', 'beamResidual_N', 'anchorResidual_N', ...
    'failedNSMlines', 'maxSteelStress_MPa', 'maxSteelMinerDamage', ...
    'concreteMinerDamage', 'cycleBlock'};
end

function proposed = update_memory(p, memory, activeNodes, peak, low, cycleBlock)
% Copy first: rejected trial blocks must not modify the accepted history.
proposed = memory;

% [F/A] Count cycles ONLY at active nodes. No constitutive formula is changed.
for bar = 1:p.nBars
    for side = 1:2
        for node = 1:p.nCells + 1
            if activeNodes{bar, side}(node)
                proposed.activated{bar, side}(node) = true;
                proposed.age{bar, side}(node) = memory.age{bar, side}(node) + cycleBlock;
            end
        end
    end
end

% [A] Optional steel S-N / Miner interface, not a supplied-paper shear law.
if isfinite(p.steelSNrefCycles) && p.Qmax > p.Qmin
    for steel = 1:p.nSteel
        stressRange = peak.steelStress(steel) - low.steelStress(steel);
        stressRange = max(0, stressRange);
        safeRange = max(stressRange, realmin);
        life = p.steelSNrefCycles * (p.steelSNrefStress / safeRange)^p.steelSNexponent;
        damageIncrement = cycleBlock / life;
        proposed.steelDamage(steel) = min(1, memory.steelDamage(steel) + damageIncrement);
    end
end

% [A] Optional concrete rule. The 41-point Vc envelope is inherited, not [S] Eq.7.
if isfinite(p.concreteSNrefCycles) && p.Qmax > p.Qmin
    qPoints = linspace(low.q, peak.q, 41);
    concreteShear = zeros(1, 41);
    for i = 1:41
        q = qPoints(i);
        w = q / p.kinematicDenominator;
        concreteShear(i) = p.VcPeak * (1 - exp(-q / p.concreteRiseQ)) ...
            * (p.concreteResidualRatio + (1 - p.concreteResidualRatio) * exp(-w / p.concreteSofteningW)) ...
            * (1 - memory.concreteDamage);
    end
    shearRange = max(concreteShear) - min(concreteShear);
    stressRange = shearRange / (p.width * p.ds);
    safeRange = max(stressRange, realmin);
    life = p.concreteSNrefCycles * (p.concreteSNrefStress / safeRange)^p.concreteSNexponent;
    proposed.concreteDamage = min(1, memory.concreteDamage + cycleBlock / life);
end
end

function row = history_row(N, peak, low, memory, cycleBlock)
% Keep exactly the same 16 columns as the uploaded function.
row = zeros(1, 16);
row(1) = N;
row(2) = peak.q;
row(3) = low.q;
row(4) = peak.w;
row(5) = peak.v;
row(6) = peak.V;
row(7) = peak.Vc;
row(8) = peak.Vs;
row(9) = peak.Vnsm;
row(10) = peak.forceResidual;
row(11) = peak.localForceResidual;
row(12) = sum(memory.failedFRP);
row(13) = max([0; peak.steelStress]);
row(14) = max([0; memory.steelDamage]);
row(15) = memory.concreteDamage;
row(16) = cycleBlock;
end

function snapshot = make_snapshot(p, N, peak, low, memory)
% A snapshot stores complete local fields at a selected cycle, not every cycle.
snapshot.N = N;
snapshot.peak = peak;
snapshot.minimum = low;
snapshot.field = cc19_sample(p, peak, memory);
snapshot.memory = memory;
snapshot.reference = cc19_paper_interpolation(p, peak);
end
