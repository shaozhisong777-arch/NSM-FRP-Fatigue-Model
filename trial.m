function st = trial(p, q, memory, unload)
% TRIAL Evaluate shear resistance at one prescribed crack displacement q.
% p: parameters and intersections. memory: accepted irreversible history.
% st: trial forces, local fields and CANDIDATE memory; no global root is solved.
% q is a crack jump, not midspan deflection.
% Preserve the uploaded constitutive formulas, failure order and output fields.

%% 1. Check q and recover the assumed crack opening/sliding profiles.
if nargin < 4
    unload = false;
end
if ~isscalar(q) || ~isfinite(q) || q < 0
    error('cc19:trial', 'q must be nonnegative.');
end
crack = cc19_curvature_integrals(p, q);
nextMemory = memory;

%% 2. Concrete shear contribution: inherited empirical closure.
% This is NOT the PST/Green-function crack-opening equation in the 2019 paper.
Vc = p.VcPeak * (1 - exp(-q / p.concreteRiseQ)) ...
    * (p.concreteResidualRatio + (1 - p.concreteResidualRatio) * exp(-crack.wMax / p.concreteSofteningW)) ...
    * (1 - memory.concreteDamage);

%% 3. Stirrup contribution: evaluate each actual crack intersection.
% p.steel(:,3) contains the prescribed crack-shape value at each stirrup.
steelStrain = zeros(p.nSteel, 1);
steelStress = zeros(p.nSteel, 1);
for steel = 1:p.nSteel
    shape = p.steel(steel, 3);
    steelStrain(steel) = q * shape / p.steelTransferLength;
    steelStress(steel) = min(p.Es * steelStrain(steel), p.fy);
    if memory.steelDamage(steel) >= 1
        steelStress(steel) = 0;
    end
end
% stirrupArea already includes the effective legs of ONE crossed stirrup.
Vs = sum(p.stirrupArea * steelStress);

%% 4. NSM contribution: solve both anchorage sides of each crossed bar.
barForce = zeros(p.nBars, 1);
bondFields = cell(p.nBars, 1);
barFailure = memory.barFailure;
localOK = true;
maxForceResidual = 0;
for bar = 1:p.nBars
    if memory.failedFRP(bar)
        continue % A previously failed bar cannot recover its force.
    end

    % Geometry columns: x, y, lower length, upper length, shape, angle (rad).
    geometry = p.bars(bar, :);
    lowerLength = geometry(3);
    upperLength = geometry(4);
    shape = geometry(5);
    angle = geometry(6);

    % Project the crack motion onto the bar axis.
    % For vertical NSM (angle=pi/2), the projection reduces to one.
    projection = (sin(p.theta + angle) - p.slidingRatio * cos(p.theta + angle)) ...
                 / p.kinematicDenominator;
    crackExtension = max(0, q * shape * projection);

    % Local aging controls the bond peak separately on the two sides.
    tauPeak1 = cc19_strength(p, memory.age{bar, 1});
    tauPeak2 = cc19_strength(p, memory.age{bar, 2});
    history1 = memory.bondMax{bar, 1};
    history2 = memory.bondMax{bar, 2};
    anchor = cc19_hard(p, crackExtension, lowerLength, upperLength, ...
                       history1, history2, tauPeak1, tauPeak2, unload);

    anchor.compatibilityResidual = abs(anchor.sides{1}.slip(1) ...
                                       + anchor.sides{2}.slip(1) - crackExtension);
    bondFields{bar} = anchor;
    localOK = localOK && anchor.ok && anchor.forceResidual <= p.forceTolerance;
    maxForceResidual = max(maxForceResidual, anchor.forceResidual);
    if ~unload
        nextMemory.bondMax{bar, 1} = anchor.sides{1}.maxSlip;
        nextMemory.bondMax{bar, 2} = anchor.sides{2}.maxSlip;
    end

    %% 5. Check this bar's failure condition, in the original priority order.
    % Node softening/residual zones are evaluated inside the anchorage solver.
    % A residual node alone does not mean that the whole bar has failed.
    failureReason = '';
    if strcmp(anchor.status, 'full_debond')
        failureReason = 'full_anchorage_debond';
    elseif anchor.force >= p.Af * p.ffu
        failureReason = 'FRP_tensile_limit';
    elseif anchor.force >= p.coverCapacityPerBar
        failureReason = 'user_cover_capacity_limit';
    end
    if ~isempty(failureReason)
        nextMemory.failedFRP(bar) = true;
        barFailure{bar} = failureReason;
        bondFields{bar}.force = 0;
        for side = 1:2
            bondFields{bar}.sides{side}.tau(:) = 0;
            bondFields{bar}.sides{side}.force(:) = 0;
            bondFields{bar}.sides{side}.strain(:) = 0;
        end
    else
        barForce(bar) = anchor.force;
    end
end

%% 6. Sum the vertical NSM forces, then add concrete and stirrup forces.
% Count each actual bar once per face; do not multiply by crack height/spacing.
if p.nBars > 0
    Vnsm = p.nsmFaces * sum(barForce .* sin(p.bars(:, 6)));
else
    Vnsm = 0;
end
nextMemory.barFailure = barFailure;

%% 7. Keep the original result field names for downstream functions.
st.q = q;
st.w = crack.wMax;
st.v = crack.vMax;
st.Vc = Vc;
st.Vs = Vs;
st.Vnsm = Vnsm;
st.V = Vc + Vs + Vnsm;
st.barForce = barForce;
st.steelStress = steelStress;
st.steelStrain = steelStrain;
st.fields = bondFields;
st.memory = nextMemory;
st.localOK = localOK;
st.localForceResidual = maxForceResidual;
st.forceResidual = NaN; % state sets this after comparison with the target load.
st.unload = unload;
end
