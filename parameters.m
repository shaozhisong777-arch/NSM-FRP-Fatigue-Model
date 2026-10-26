function p = parameters(kind)
    % Parameter function. Input: kind. Output: parameter structure p. Edit defaults here.

    if nargin < 1
        kind = 'strip';
    end
    kind = lower(char(kind));
    if ~any(strcmp(kind, {'rod', 'strip'}))
        error('parameters:input', 'kind must be rod or strip.');
    end
    p.kind = kind;

    %% Beam geometry and assumed crack
    p.width = 180; % mm
    p.depth = 400; % mm
    p.flangeWidth = 450; % mm
    p.flangeDepth = 100; % mm
    p.fc = 39.7; % MPa
    p.Ec = 30000; % MPa
    p.ds = 360; % mm
    p.shearSpan = 900; % mm
    p.span = 2400; % mm
    p.crackHeight = 300; % mm
    p.crackOriginX = 100; % mm
    % Chen and Cheng (2019), Eqs. (2a)/(2b), for shear span/depth ratios from 1 to 3.5.
    spanRatio = p.shearSpan / p.depth;
    if spanRatio >= 1 && spanRatio <= 2.5
        p.thetaDeg = 57.1 - 12.84 * spanRatio;
    elseif spanRatio > 2.5 && spanRatio <= 3.5
        p.thetaDeg = 25;
    else
        p.thetaDeg = NaN; % Outside the empirical range; specify a measured thetaDeg.
    end
    p.slidingRatio = 0.20;                % Sliding-to-opening ratio, v/w.
    p.crackShapeExponent = 1;             % g(y)=(1-y/hc)^exponent

    %% NSM strip parameters; rod-specific values are assigned below
    p.Ef = 170900; % MPa
    p.Af = 1.4 * 9.5; % mm^2
    p.perimeter = 2 * (1.4 + 9.5); % mm
    p.alphaDeg = 60;
    p.nsmSpacing = 243; % mm
    p.nsmFirstX = 121.5; % mm, bottom-end x coordinate of the first NSM reinforcement
    p.nsmYBottom = 15;
    p.nsmYTop = 300;
    p.nsmFaces = 2; % two sides
    p.nsmSegments = [];  % [x_bottom,y_bottom,x_top,y_top] only one side
    p.nsmEnabled = true;
    p.ffu = 2500; % MPa   experimental work value
    p.coverCapacityPerBar = Inf;

    %% Bond and fatigue parameters
    p.tauM0 = 15.72; % MPa, initial peak bond stress
    p.tauR = 1.53; % MPa, residual bond stress
    p.deltaM = 0.2; % mm, slip at peak bond stress
    p.deltaU = 0.7; % mm, slip at the start of the residual branch
    p.bondFatigueK = 0.1985;            % Fatigue paper, Eq. (2): NSM strip
    p.activationFraction = 0.75;
    if strcmp(kind, 'rod')
        p.bondFatigueK = 0.1965; % Fatigue paper, Eq. (2): NSM rod
        % Rod parameters
        p.Ef = 136000; % MPa
        p.Af = pi * 9^2 / 4; % mm^2
        p.perimeter = pi * 9; % mm total length
        p.tauM0 = 11.35; % MPa, initial peak bond stress
        p.tauR = 1; % MPa, residual bond stress
        p.deltaM = 0.5; % mm, slip at peak bond stress
        p.deltaU = 1.4; % mm, slip at the start of the residual branch
        p.activationFraction = 0.75;
    end
    %% Stirrup parameters
    p.Es = 200000; % MPa
    p.stirrupArea = 2 * pi * 6^2 / 4;
    p.fy = 542; % MPa
    p.stirrupSpacing = 300; % mm
    p.stirrupFirstX = 150; % mm location
    p.stirrupX = [];
    p.steelTransferLength = 220; % mm

    %% Simplified concrete response; inherited empirical closure, not paper Eq. (7)
    p.VcPeak = 60000; % N, empirical amplitude from the original model, not a paper-derived peak
    p.concreteRiseQ = 0.025; % mm, empirical closure parameter from the original model
    p.concreteSofteningW = 0.60; % mm, empirical closure parameter from the original model
    p.concreteResidualRatio = 0.20; % Dimensionless coefficient

    p.steelSNrefCycles = Inf;
    p.steelSNrefStress = 200;
    p.steelSNexponent = 5;
    p.concreteSNrefCycles = Inf;
    p.concreteSNrefStress = 1;
    p.concreteSNexponent = 8;
    p.shearStrutLimit = Inf;
    p.flexuralMomentLimit = Inf; % Independently specified limit
    %% Loading and numerical controls
    p.Qmax = 180000;
    p.Qmin = 30000;
    p.Nmax = 10000;
    p.cycleStep = 20;
    p.nCells = 24;                     % Number of elements on each anchorage side
    p.maxQ = 5;
    p.scanPoints = 61;
    p.forceTolerance = 0.05;
    p.slipTolerance = 1e-8;
    p.localTolerance = 1e-8;
    p.localMaxIterations = 350;
    p.maxOpeningStep = 0.08;
    p.cyclicSlipTolerance = 1e-10;       % Qmax=Qmin
    p.snapshotCycles = [0 1 10 100 1000 10000];
    %% Output options
    p.makePlots = true;
    p.exportResults = true;
    p.verbose = true;
    p.computeCapacity = true;
    p.outputDir = fullfile(fileparts(mfilename('fullpath')), ['results_20_NSM_shear_' kind]);
    p.sourceNotes = struct();
end
