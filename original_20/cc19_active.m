function [active,amplitude] = cc19_active(p,peak,low,memory)

active=cell(p.nBars,2); 
amplitude=cell(p.nBars,2);
for j=1:p.nBars % FRP different sides
 for s=1:2% FRP different sides
  active{j,s}=false(p.nCells+1,1); 
  amplitude{j,s}=zeros(p.nCells+1,1);
  if p.Qmax==p.Qmin||memory.failedFRP(j)||isempty(peak.fields{j})||isempty(low.fields{j}), continue; 
  end
  a=peak.fields{j}.sides{s}; b=low.fields{j}.sides{s};
  amplitude{j,s}=max(0,a.slip-b.slip);
  active{j,s}=(memory.activated{j,s}|a.maxSlip>p.activationFraction*p.deltaM) ...
   & amplitude{j,s}>p.cyclicSlipTolerance;
 end
end
end
