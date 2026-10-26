% Shared parameter script. Set kind to strip or rod before running.
% Default: strip. Run parameters to load variables into the current workspace.

if ~exist('kind', 'var') || isempty(kind)
    kind = 'strip';
end
kind = lower(char(kind));
if ~any(strcmp(kind, {'rod', 'strip'}))
    error('cc19:input', 'kind must be rod or strip.');
end

%% Beam geometry and assumed crack
width = 180; % mm
depth = 400; % mm
flangeWidth = 450; % mm
flangeDepth = 100; % mm
fc = 39.7; % MPa
Ec = 30000; % MPa
ds = 360; % mm
shearSpan = 900; % mm
span = 2400; % mm
crackHeight = 300; % mm
crackOriginX = 100; % mm
% Chen and Cheng (2019), Eqs. (2a)/(2b), for shear span/depth ratios from 1 to 3.5.
spanRatio = shearSpan / depth;
if spanRatio >= 1 && spanRatio <= 2.5
    thetaDeg = 57.1 - 12.84 * spanRatio;
elseif spanRatio > 2.5 && spanRatio <= 3.5
    thetaDeg = 25;
else
    thetaDeg = NaN; % Outside the empirical range; specify a measured thetaDeg.
end
slidingRatio = 0.20;                % Sliding-to-opening ratio, v/w.
crackShapeExponent = 1;             % g(y)=(1-y/hc)^exponent

%% NSM strip parameters; rod-specific values are assigned below
Ef = 170900; % MPa
Af = 1.4 * 9.5; % mm^2
perimeter = 2 * (1.4 + 9.5); % mm
alphaDeg = 60;
nsmSpacing = 243; % mm
nsmFirstX = 121.5; % mm, bottom-end x coordinate of the first NSM reinforcement
nsmYBottom = 15;
nsmYTop = 300;
nsmFaces = 2; % two sides
nsmSegments = [];  % [x_bottom,y_bottom,x_top,y_top] only one side
nsmEnabled = true;
ffu = 2500; % MPa   experimental work value
coverCapacityPerBar = Inf;

%% Bond and fatigue parameters
tauM0 = 15.72; % MPa, initial peak bond stress
tauR = 1.53; % MPa, residual bond stress
deltaM = 0.2; % mm, slip at peak bond stress
deltaU = 0.7; % mm, slip at the start of the residual branch
bondFatigueK = 0.1985;            % Fatigue paper, Eq. (2): NSM strip
activationFraction = 0.75;
if strcmp(kind, 'rod')
    bondFatigueK = 0.1965; % Fatigue paper, Eq. (2): NSM rod
    % Rod parameters
    Ef = 136000; % MPa
    Af = pi * 9^2 / 4; % mm^2
    perimeter = pi * 9; % mm, bonded perimeter
    tauM0 = 11.35; % MPa, initial peak bond stress
    tauR = 1; % MPa, residual bond stress
    deltaM = 0.5; % mm, slip at peak bond stress
    deltaU = 1.4; % mm, slip at the start of the residual branch
    activationFraction = 0.75;
end
%% Stirrup parameters
Es = 200000; % MPa
stirrupArea = 2 * pi * 6^2 / 4;
fy = 542; % MPa
stirrupSpacing = 300; % mm
stirrupFirstX = 150; % mm location
stirrupX = [];
steelTransferLength = 220; % mm

%% Simplified concrete response; inherited empirical closure, not paper Eq. (7)
VcPeak = 60000; % N, empirical amplitude from the original model, not a paper-derived peak
concreteRiseQ = 0.025; % mm, empirical closure parameter from the original model
concreteSofteningW = 0.60; % mm, empirical closure parameter from the original model
concreteResidualRatio = 0.20; % Dimensionless coefficient

steelSNrefCycles = Inf;
steelSNrefStress = 200;
steelSNexponent = 5;
concreteSNrefCycles = Inf;
concreteSNrefStress = 1;
concreteSNexponent = 8;
shearStrutLimit = Inf;
flexuralMomentLimit = Inf; % Independently specified limit
%% Loading and numerical controls
Qmax = 180000;
Qmin = 30000;
Nmax = 10000;
cycleStep = 20;
nCells = 24;                     % Number of elements on each anchorage side
maxQ = 5;
scanPoints = 61;
forceTolerance = 0.05;
slipTolerance = 1e-8;
localTolerance = 1e-8;
localMaxIterations = 350;
maxOpeningStep = 0.08;
cyclicSlipTolerance = 1e-10;       % Qmax=Qmin
snapshotCycles = [0 1 10 100 1000 10000];
%% Output options
makePlots = true;
exportResults = true;
verbose = true;
computeCapacity = true;
outputDir = fullfile(fileparts(mfilename('fullpath')), ['results_20_NSM_shear_' kind]);
sourceNotes = struct();
