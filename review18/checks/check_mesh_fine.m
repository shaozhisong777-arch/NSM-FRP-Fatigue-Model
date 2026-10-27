reviewDir = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(reviewDir,'results');
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(reviewDir,'source'),'-begin');
rows=[];
for cells=[192 384]
 p=parameters('strip');p.alphaDeg=90;p.nCells=cells;p.scanPoints=61;
 p.Nmax=100;p.makePlots=false;p.exportResults=false;p.verbose=false;p.computeCapacity=false;
 tic;o=fatigue_calculate(p);elapsed=toc;
 H=o.history;
 if isempty(H); row=[cells NaN NaN NaN NaN NaN elapsed];else;row=[cells H(1,2) H(end,2) H(end,7:9) elapsed];end
 rows=[rows;row];
 fprintf('MESH cells=%d status=%s N=%g data=%s\n',cells,o.status,o.lastCycle,mat2str(row,12));fflush(stdout);
end
save(fullfile(resultDir,'mesh_fine.mat'),'rows','-v7');
