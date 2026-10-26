function v = cc19_sample(p,st,memory)

if nargin<3, memory=st.memory; end
rows=zeros(0,12);
for j=1:p.nBars
 if isempty(st.fields{j}), continue; end
 for s=1:2
  a=st.fields{j}.sides{s}; n=numel(a.x);
  rows=[rows; j*ones(n,1),s*ones(n,1),a.x,a.slip,a.maxSlip,a.tau,a.tauM, ...
   a.force,a.strain,memory.age{j,s},a.zone,memory.failedFRP(j)*ones(n,1)];
 end
end
v=struct('NSMfields',rows,'columns',{{'bar','side','x_mm','slip_mm','maxSlip_mm', ...
 'bondStress_MPa','peakBondStress_MPa','axialForce_N','FRPstrain','localCycles','zone','barFailed'}}, ...
 'steel',[p.steel,st.steelStrain,st.steelStress,memory.steelDamage], ...
 'crack',cc19_curvature_integrals(p,st.q));
end
