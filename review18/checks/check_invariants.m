reviewDir = fileparts(fileparts(mfilename('fullpath')));
resultDir = fullfile(reviewDir,'results');
if ~exist(resultDir,'dir'); mkdir(resultDir); end
addpath(fullfile(reviewDir,'source'),'-begin');
p=parameters('strip');p.nCells=24;p=prepare_parameters(p);
m.bondMax=cell(p.nBars,2);m.age=cell(p.nBars,2);m.activated=cell(p.nBars,2);
m.failedFRP=false(p.nBars,1);m.barFailure=repmat({''},p.nBars,1);m.steelDamage=zeros(p.nSteel,1);m.concreteDamage=0;
for b=1:p.nBars;for s=1:2;m.bondMax{b,s}=zeros(p.nCells+1,1);m.age{b,s}=zeros(p.nCells+1,1);m.activated{b,s}=false(p.nCells+1,1);end;end
[a,info]=state(p,m,p.Qmax/2,0,false);assert(info.ok);
before=m;[low,li]=state(p,a.memory,p.Qmin/2,a.q,true);assert(li.ok);
assert(isequaln(before,m));assert(isequaln(low.memory.bondMax,a.memory.bondMax));
compat=0;fr=0;endForce=0;
for b=1:p.nBars
 f=a.fields{b};if isempty(f);continue;end
 compat=max(compat,f.compatibilityResidual);fr=max(fr,f.forceResidual);
 for side=1:2;z=f.sides{side};endForce=max(endForce,z.force(end));assert(all(z.maxSlip>=z.slip-1e-10));end
end
fprintf('INITIAL_INVARIANTS global=%.12g local=%.12g compatibility=%.12g endForce=%.12g unloadResidual=%.12g\n',a.forceResidual,fr,compat,endForce,low.forceResidual);
% Bond envelope boundary and degradation tests.
s=[0 p.deltaM p.deltaU 2*p.deltaU];[tau,k,z]=bond(p,s,p.tauM0);
assert(isequal(z,[1 1 2 3]));assert(max(abs(tau-[0 p.tauM0 p.tauR p.tauR]))<1e-10);
N=[0 1 10 1000 1e12];tm=bond_strength(p,N);assert(all(diff(tm)<=0)&&tm(end)==0);
p90=p;p90.alphaDeg=90;p90=prepare_parameters(p90);
projection=(sin(p90.theta+p90.bars(:,6))-p90.slidingRatio*cos(p90.theta+p90.bars(:,6)))/p90.kinematicDenominator;
assert(max(abs(projection-1))<1e-12);
fprintf('BOND_BOUNDARIES_AND_VERTICAL_PROJECTION_PASSED\n');
