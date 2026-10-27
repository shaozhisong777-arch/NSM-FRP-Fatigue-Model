reviewDir = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(reviewDir,'results');
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(reviewDir,'source'),'-begin');
p=parameters('strip');p.makePlots=false;p.exportResults=false;p.verbose=false;p.computeCapacity=false;p.nCells=12;p.scanPoints=41;p.Nmax=1;
a=fatigue_calculate(p);
q=p;q.fc=p.fc*2;q.Ec=p.Ec*2;b=fatigue_calculate(q);
fprintf('FC_EC_SENSITIVITY_EQUAL=%d\n',isequaln(a.history,b.history));
p2=parameters('strip');p2.shearSpan=800;p2=prepare_parameters(p2);
fprintf('ANGLE_OVERRIDE actual=%g formula=%g\n',p2.thetaDeg,57.1-12.84*p2.shearSpan/p2.depth);
% Invalid activation type/vector: the validator should reject before calculation.
for value={NaN,[.5 .75],1+1i}
 t=parameters('strip');t.activationFraction=value{1};
 try;prepare_parameters(t);fprintf('ACTIVATION_INVALID_ACCEPTED %s\n',mat2str(value{1}));catch err;fprintf('ACTIVATION_REJECTED %s id=%s\n',mat2str(value{1}),err.identifier);end
end
% Nonfinite geometry must not silently create a zero-bar case.
for name={'nsmYBottom','nsmYTop'}
 t=parameters('strip');t.(name{1})=NaN;
 try;t=prepare_parameters(t);fprintf('GEOMETRY_NAN_ACCEPTED %s bars=%d\n',name{1},t.nBars);catch err;fprintf('GEOMETRY_NAN_REJECTED %s id=%s\n',name{1},err.identifier);end
end
% Boundary force limit at initial loading.
t=p;t.shearStrutLimit=1;r=fatigue_calculate(t);
fprintf('INITIAL_LIMIT status=%s failureCycle=%g bracket=%s\n',r.status,r.failureCycle,mat2str(r.failureBracket));
% Independent failure controls.
t=p;t.Qmax=1e9;r=fatigue_calculate(t);fprintf('OVERLOAD status=%s N=%g\n',r.status,r.failureCycle);
t=p;t.Nmax=100;t.Qmin=t.Qmax;r=fatigue_calculate(t);fprintf('CONSTANT status=%s N=%g age=%g\n',r.status,r.lastCycle,max([0;vertcat(r.memory.age{:})]));
% Reproducibility.
b=fatigue_calculate(p);fprintf('REPEAT_EQUAL=%d\n',isequaln(a.history,b.history)&&isequaln(a.memory,b.memory));
% Source closure: only active project files on path, no legacy dependencies.
fprintf('ENTRY=%s\n',which('read_and_calculate'));
