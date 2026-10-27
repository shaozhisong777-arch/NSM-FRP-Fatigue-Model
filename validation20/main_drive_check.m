validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(projectDir);
% Run a temporary copy with short-run overrides; do not change main_drive.
source = fileread(fullfile(projectDir,'main_drive.m'));
assert(isempty(strfind(source,'ff19(')));
assert(~isempty(strfind(source,'out = read_and_calculate(kind, options);')));
shortSettings = sprintf(['options = struct();\noptions.Nmax = 1;\n' ...
    'options.nCells = 8;\noptions.scanPoints = 15;\n' ...
    'options.computeCapacity = false;\noptions.makePlots = false;\n' ...
    'options.exportResults = false;\noptions.verbose = false;']);
source = strrep(source,'options = struct();',shortSettings);
% Keep the real project directory when executing the temporary copy.
source = strrep(source,"here = fileparts(mfilename('fullpath'));", ...
    ['here = ''' strrep(projectDir,'''','''''') ''';']);
eval(source);
assert(isstruct(out) && ~isempty(out.history));
assert(out.parameters.Nmax == 1);
assert(~isfield(out.snapshots,'reference'));
assert(strcmp(which('fatigue_calculate'),fullfile(here,'fatigue_calculate.m')));
fprintf('MAIN_DRIVE_SHORT_RUN_PASSED: status=%s, historyRows=%d\n', ...
    out.status,size(out.history,1));
