function p = cc19_parameters(kind)
    % 参数文件。输入kind；输出p。所有常用默认参数集中在这里修改。

    if nargin < 1
        kind = 'strip';
    end
    kind = lower(char(kind));
    if ~any(strcmp(kind, {'rod', 'strip'}))
        error('cc19:input', 'kind must be rod or strip.');
    end
    p.kind = kind;

    %% 试件几何及假定裂缝
    p.width = 180; % mm
    p.depth = 400; % mm
    p.flangeWidth = 450; % mm
    p.flangeDepth = 100; % mm
    p.fc = 39.7; % Mpa
    p.Ec = 30000; % Mpa
    p.ds = 360; % mm
    p.shearSpan = 900; % mm
    p.span = 2400; % mm
    p.crackHeight = 300; % mm
    p.crackOriginX = 100; % mm
    % Chen & Cheng 2019，式(2a)/(2b)：适用剪跨高比1~3.5。
    spanRatio = p.shearSpan / p.depth;
    if spanRatio >= 1 && spanRatio <= 2.5
        p.thetaDeg = 57.1 - 12.84 * spanRatio;
    elseif spanRatio > 2.5 && spanRatio <= 3.5
        p.thetaDeg = 25;
    else
        p.thetaDeg = NaN; % 超出经验范围时，需要用户提供实测thetaDeg。
    end
    p.slidingRatio = 0.20;                % v/w，
    p.crackShapeExponent = 1;             % g(y)=(1-y/hc)^exponent

    %% NSM条材参数（杆材差异在下面if中给出）
    p.Ef = 170900; % Mpa
    p.Af = 1.4 * 9.5; % mm^2
    p.perimeter = 2 * (1.4 + 9.5); % mm
    p.alphaDeg = 60;
    p.nsmSpacing = 243; % mm
    p.nsmFirstX = 121.5; % location for the first nsm
    p.nsmYBottom = 15;
    p.nsmYTop = 300;
    p.nsmFaces = 2; % two sides
    p.nsmSegments = [];  % [x_bottom,y_bottom,x_top,y_top] only one side
    p.nsmEnabled = true;
    p.ffu = 2500; % Mpa   experimental work value
    p.coverCapacityPerBar = Inf;

    %% 黏结和疲劳参数
    p.tauM0 = 15.72; % MPa，初始峰值
    p.tauR = 1.53; % MPa，残余值
    p.deltaM = 0.2; % mm，峰值黏结应力对应滑移
    p.deltaU = 0.7; % mm，进入残余段的滑移
    p.bondFatigueK = 0.1985;            % 疲劳论文式(2)：条材
    p.activationFraction = 0.75;
    if strcmp(kind, 'rod')
        p.bondFatigueK = 0.1965; % 疲劳论文式(2)：杆材
        % 杆材参数
        p.Ef = 136000; % Mpa
        p.Af = pi * 9^2 / 4; % mm^2
        p.perimeter = pi * 9; % mm total length
        p.tauM0 = 11.35; % MPa，初始峰值
        p.tauR = 1; % MPa，残余值
        p.deltaM = 0.5; % mm，峰值黏结应力对应滑移
        p.deltaU = 1.4; % mm，进入残余段的滑移
        p.activationFraction = 0.75;
    end
    %% 箍筋参数
    p.Es = 200000; % Mpa
    p.stirrupArea = 2 * pi * 6^2 / 4;
    p.fy = 542; % Mpa
    p.stirrupSpacing = 300; % mm
    p.stirrupFirstX = 150; % mm location
    p.stirrupX = [];
    p.steelTransferLength = 220; % mm

    %% 混凝土简化响应（沿用原经验闭合，非论文式7）
    p.VcPeak = 60000; % N；原模型的经验幅值，不是论文推导出的峰值
    p.concreteRiseQ = 0.025; % mm；原模型经验闭合参数
    p.concreteSofteningW = 0.60; % mm；原模型经验闭合参数
    p.concreteResidualRatio = 0.20; % cofficent

    p.steelSNrefCycles = Inf;
    p.steelSNrefStress = 200;
    p.steelSNexponent = 5;
    p.concreteSNrefCycles = Inf;
    p.concreteSNrefStress = 1;
    p.concreteSNexponent = 8;
    p.shearStrutLimit = Inf;
    p.flexuralMomentLimit = Inf; % independ values
    %% 荷载及数值计算控制
    p.Qmax = 180000;
    p.Qmin = 30000;
    p.Nmax = 10000;
    p.cycleStep = 20;
    p.nCells = 24;                     % 每侧锚固划分的单元数
    p.maxQ = 5;
    p.scanPoints = 61;
    p.forceTolerance = 0.05;
    p.slipTolerance = 1e-8;
    p.localTolerance = 1e-8;
    p.localMaxIterations = 350;
    p.maxOpeningStep = 0.08;
    p.cyclicSlipTolerance = 1e-10;       % Qmax=Qmin
    p.snapshotCycles = [0 1 10 100 1000 10000];
    %% 输出开关
    p.makePlots = true;
    p.exportResults = true;
    p.verbose = true;
    p.computeCapacity = true;
    p.outputDir = fullfile(fileparts(mfilename('fullpath')), ['results_20_NSM_shear_' kind]);
    p.calibrationStatus = 'not_calibrated_for_NSM_shear_fatigue';
    p.codeVersion = 'original20-readable-v2';
    p.sourceNotes = struct();
    p.sourceNotes.shear = 'Chen and Cheng 2019, DOI 10.1061/(ASCE)CC.1943-5614.0000953; angle Eq.2, two-sided compatibility Eqs.9d,11';
    p.sourceNotes.fatigue = 'Chen et al. 2019, DOI 10.1016/j.ijfatigue.2019.04.039; Eq.2: rod 0.1965, strip 0.1985, activation 0.75*deltaM';
    p.sourceNotes.limit = 'Inherited prescribed crack shape and empirical Vc; PST/Green-function crack-opening Eq.7 NOT implemented';
    p.sourceNotes.residual = 'Numerical extension: residual=min(tauR,currentPeak) if peak degrades below tauR; not a new calibrated material law';
end
