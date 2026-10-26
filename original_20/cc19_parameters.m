function p = cc19_parameters(kind)

if nargin < 1, kind = 'strip'; end
kind = lower(char(kind));
if ~any(strcmp(kind,{'rod','strip'})), error('cc19:input','kind must be rod or strip.'); end
p.kind = kind;

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
p.crackOriginX = 100;% mm
p.thetaDeg = 57.1-12.84*(p.shearSpan/p.depth); % equation paper 2019 2a
p.slidingRatio = 0.20;                % v/w，
p.crackShapeExponent = 1;             % g(y)=(1-y/hc)^exponent

% values for NSM strip 
p.Ef = 170900; % Mpa
p.Af = 1.4*9.5; % mm^2
p.perimeter = 2*(1.4+9.5); % mm
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

% bonded values 
p.tauM0 = 15.72; % Mpa initial 
p.tauR = 1.53; % Mpa residual 
p.deltaM = 0.2; % mm max slip
p.deltaU = 0.7; % mm residual slip
p.bondFatigueK = 0.1965;            % decrease value 0.1985
p.activationFraction = 0.75;
if strcmp(kind,'rod')
    % rod values
    p.Ef = 136000; % Mpa
    p.Af = pi*9^2/4; % mm^2
    p.perimeter = pi*9; %mm total length
    p.tauM0 = 11.35; % Mpa initial 
    p.tauR = 1; % Mpa residual
    p.deltaM = 0.5;% mm max slip
    p.deltaU = 1.4;% mm residual slip
    p.activationFraction = 0.70;
end
% striup values
p.Es = 200000; % Mpa
p.stirrupArea = 2*pi*6^2/4; 
p.fy = 542;% Mpa
p.stirrupSpacing = 300; % mm
p.stirrupFirstX = 150; % mm location
p.stirrupX = []; 
p.steelTransferLength = 220; % mm

% concrete values
p.VcPeak = 60000; % Kn
p.concreteRiseQ = 0.025; % cofficent 
p.concreteSofteningW = 0.60; % cofficent
p.concreteResidualRatio = 0.20; % cofficent


p.steelSNrefCycles = Inf; 
p.steelSNrefStress = 200;
p.steelSNexponent = 5;
p.concreteSNrefCycles = Inf; 
p.concreteSNrefStress = 1; 
p.concreteSNexponent = 8;
p.shearStrutLimit = Inf;
p.flexuralMomentLimit = Inf; % independ values
p.Qmax = 180000; 
p.Qmin = 30000;     
p.Nmax = 10000; 
p.cycleStep = 20;
p.nCells = 24;                     % mesh members
p.maxQ = 5;
p.scanPoints = 61;
p.forceTolerance = 0.05;
p.slipTolerance = 1e-8;
p.localTolerance = 1e-8; 
p.localMaxIterations = 350;
p.maxOpeningStep = 0.08;
p.cyclicSlipTolerance = 1e-10;       % Qmax=Qmin
p.snapshotCycles = [0 1 10 100 1000 10000];
p.makePlots = true; 
p.exportResults = true;
p.verbose = true; 
p.computeCapacity = true;
p.outputDir = ['results_NSM_shear_' kind];
p.calibrationStatus = 'not_calibrated_for_NSM_shear_fatigue';
end
