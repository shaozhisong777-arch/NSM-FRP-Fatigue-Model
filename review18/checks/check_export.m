reviewDir = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(reviewDir,'results');
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(reviewDir,'source'),'-begin');
p=parameters('strip');p.nCells=8;p.scanPoints=15;p.Nmax=2;p.verbose=false;
p.makePlots=false;p.exportResults=false;
o=fatigue_calculate(p);
graphics_toolkit('gnuplot');set(0,'defaultfigurevisible','off');
o.parameters.makePlots=true;o.parameters.exportResults=true;
o.parameters.outputDir=fullfile(resultDir,'export_smoke');
figs=export_results(o);assert(numel(figs)==10);
pngs=dir(fullfile(o.parameters.outputDir,'*.png'));csvs=dir(fullfile(o.parameters.outputDir,'*.csv'));
assert(numel(pngs)==10);assert(numel(csvs)==15);
loaded=load(fullfile(o.parameters.outputDir,'results_NSM_shear.mat'));
assert(isequaln(loaded.out,o));
close all;
fprintf('EXPORT_PASSED: figures=%d csv=%d MAT_roundtrip=1, Nmax=2\n',numel(pngs),numel(csvs));
