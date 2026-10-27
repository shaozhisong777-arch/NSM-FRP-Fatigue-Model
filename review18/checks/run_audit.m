reviewDir = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(reviewDir,'results');
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(reviewDir,'source'),'-begin');
p=parameters('strip');p.makePlots=false;p.exportResults=false;p.verbose=false;
tic;out=fatigue_calculate(p);elapsed=toc;
H=out.history;
fprintf('DEFAULT status=%s N=%g rows=%d seconds=%g nBars=%d nSteel=%d angle=%g theta=%g\n',out.status,out.lastCycle,size(H,1),elapsed,out.parameters.nBars,out.parameters.nSteel,out.parameters.alphaDeg,out.parameters.thetaDeg);
fprintf('q0=%.12g qEnd=%.12g Vc=%.12g Vs=%.12g Vf=%.12g globalResidual=%.12g localResidual=%.12g failed=%g maxAge=%g\n',H(1,2),H(end,2),H(end,7:9),max(H(:,10)),max(H(:,11)),H(end,12),max([0;vertcat(out.memory.age{:})]));
assert(all(abs(H(:,6)-sum(H(:,7:9),2))<1e-7));
assert(all(H(:,10)<=p.forceTolerance));
assert(all(diff(H(:,1))>0));
assert(all(diff(H(:,2))>=-p.slipTolerance));
assert(~isfield(out.snapshots,'reference'));
save(fullfile(resultDir,'default.mat'),'out','elapsed','-v7');
% Vertical case: actual user geometry differs from uploaded default angle.
p.alphaDeg=90;tic;vertical=fatigue_calculate(p);elapsed90=toc;
fprintf('VERTICAL status=%s N=%g rows=%d seconds=%g nBars=%d qEnd=%.12g\n',vertical.status,vertical.lastCycle,size(vertical.history,1),elapsed90,vertical.parameters.nBars,vertical.history(end,2));
save(fullfile(resultDir,'vertical.mat'),'vertical','elapsed90','-v7');
