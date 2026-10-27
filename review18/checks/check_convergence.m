reviewDir = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(reviewDir,'results');
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(reviewDir,'source'),'-begin');
rows=[];
for cells=[12 24 48 96]
 p=parameters('strip');p.alphaDeg=90;p.nCells=cells;p.scanPoints=61;
 p.Nmax=100;p.makePlots=false;p.exportResults=false;p.verbose=false;p.computeCapacity=false;
 tic;o=fatigue_calculate(p);elapsed=toc;
 H=o.history;
 if isempty(H); row=[cells NaN NaN NaN NaN NaN elapsed];else;row=[cells H(1,2) H(end,2) H(end,7:9) elapsed];end
 rows=[rows;row];
 fprintf('MESH cells=%d status=%s N=%g data=%s\n',cells,o.status,o.lastCycle,mat2str(row,12));fflush(stdout);
end
save(fullfile(resultDir,'mesh.mat'),'rows','-v7');
% Cycle-block convergence at fixed vertical grid under active degradation.
steps=[];
for step=[1 5 20 100]
 p=parameters('strip');p.alphaDeg=90;p.nCells=24;p.scanPoints=61;
 p.Nmax=100;p.cycleStep=step;p.makePlots=false;p.exportResults=false;p.verbose=false;p.computeCapacity=false;
 o=fatigue_calculate(p);H=o.history;
 row=[step H(end,2) H(end,7:9) max([0;vertcat(o.memory.age{:})])];steps=[steps;row];
 fprintf('STEP step=%d status=%s N=%g data=%s\n',step,o.status,o.lastCycle,mat2str(row,12));fflush(stdout);
end
save(fullfile(resultDir,'step.mat'),'steps','-v7');
