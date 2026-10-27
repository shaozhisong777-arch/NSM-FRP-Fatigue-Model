validationDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(validationDir);
addpath(fullfile(projectDir,'code20'));
addpath(projectDir);
workDir = tempname;
mkdir(workDir);
p = parameters('strip'); p.Nmax = 2; p.nCells = 8; p.scanPoints = 15;
p.makePlots = false; p.exportResults = false; p.verbose = false;
p.computeCapacity = true;
out = fatigue_calculate(p);
assert(~isfield(out.snapshots,'reference'));
oldOut = cc19_run(p);
oldOut.snapshots = rmfield(oldOut.snapshots,'reference');
fields = {'history','memory','snapshots','initialCapacity','lastState', ...
    'lastLowState','failureCycle','failureBracket','status'};
for item = 1:numel(fields)
    name = fields{item};
    assert(isequaln(out.(name),oldOut.(name)));
end
fprintf('CORE_OUTPUTS_EXACT_AFTER_REMOVING_REFERENCE\n');
old = out; old.parameters.exportResults = true;
old.parameters.outputDir = fullfile(workDir,'old');
cc19_export(old);
new = out; new.parameters.exportResults = true;
new.parameters.outputDir = fullfile(workDir,'new');
export_results(new);
files = dir(fullfile(old.parameters.outputDir,'*.csv'));
for item = 1:numel(files)
    oldText = fileread(fullfile(old.parameters.outputDir,files(item).name));
    newText = fileread(fullfile(new.parameters.outputDir,files(item).name));
    assert(strcmp(oldText,newText));
end
assert(strcmp(fileread(fullfile(old.parameters.outputDir,'status_and_sources.txt')), ...
    fileread(fullfile(new.parameters.outputDir,'status_and_sources.txt'))));
loaded = load(fullfile(new.parameters.outputDir,'results_NSM_shear.mat'));
assert(isequaln(loaded.out,new));
fprintf('CSV_AND_STATUS_EXACT; MAT_ROUNDTRIP_PASSED; csvFiles=%d\n',numel(files));
assert(isempty(export_results(out)));
graphics_toolkit('gnuplot');
set(0,'defaultfigurevisible','off');
new.parameters.makePlots = true;
new.parameters.outputDir = fullfile(workDir,'plots');
figs = export_results(new);
assert(numel(figs)==10);
images = dir(fullfile(new.parameters.outputDir,'figure_*.png'));
assert(numel(images)==10);
for item = 1:numel(images)
    assert(images(item).bytes > 1000);
end
close all;
fprintf('ALL10_FIGURES_EXPORTED; folder=%s\n',new.parameters.outputDir);
% Export an initial failure with no balanced history or snapshots.
failed = out; failed.history = zeros(0,size(out.history,2));
failed.snapshots = []; failed.parameters.exportResults = true;
failed.parameters.makePlots = false;
failed.parameters.outputDir = fullfile(workDir,'empty_history');
export_results(failed);
assert(exist(fullfile(failed.parameters.outputDir,'history.csv'),'file')==2);
fprintf('EMPTY_HISTORY_EXPORT_PASSED\n');
% A supplied figure list is preserved if file writing is disabled.
f = figure('visible','off');
assert(isequal(export_results(out,f),f));
close(f);
% Verify the renamed caller, not only the export helper.
overrides.Nmax = 1; overrides.nCells = 8; overrides.scanPoints = 15;
overrides.computeCapacity = false; overrides.makePlots = false;
overrides.exportResults = true; overrides.verbose = false;
overrides.outputDir = fullfile(workDir,'entry');
entry = read_and_calculate('strip',overrides);
assert(~isfield(entry.snapshots,'reference'));
assert(exist(fullfile(overrides.outputDir,'results_NSM_shear.mat'),'file')==2);
fprintf('READ_AND_CALCULATE_EXPORT_ENTRY_PASSED\nALL_EXPORT_CHECKS_PASSED\n');
