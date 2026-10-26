function [st,info] = cc19_state(p,memory,Vtarget,previousQ,unload)
% Vtarget=Vc(q)+Vs(q)+V_NSM(q)
if nargin<4, previousQ=0; end
if nargin<5, unload=false; end
info=struct('ok',false,'status','no_equilibrium_in_model_domain','capacity',NaN, ...
 'numericalFailures',0,'message',''); st=[];
if Vtarget>p.shearStrutLimit
 info.status='user_concrete_strut_limit'; return; end
if Vtarget*p.shearSpan>p.flexuralMomentLimit
 info.status='user_flexural_limit'; return; end
if unload, lo=0; hi=max(previousQ,p.slipTolerance); else, lo=max(0,previousQ); hi=p.maxQ; end
if lo>hi, info.status='opening_limit_reached'; return; end
xs=unique([lo,linspace(lo,min(0.15,hi),12),linspace(lo,hi,p.scanPoints),hi]);
xs=xs(xs>=lo & xs<=hi); peak=-Inf; prev=[]; prevR=NaN; prevX=NaN;
for i=1:numel(xs)
 cur=cc19_trial(p,xs(i),memory,unload);
 if ~cur.localOK
  info.numericalFailures=info.numericalFailures+1; prev=[]; continue;
 end
 r=cur.V-Vtarget; peak=max(peak,cur.V);
 if abs(r)<=p.forceTolerance
  st=cur; info.ok=true; break;
 end
 if ~isempty(prev)&&prevR<0&&r>0
  left=prevX; right=xs(i);
  for it=1:70
   mid=(left+right)/2; z=cc19_trial(p,mid,memory,unload);
   if ~z.localOK, info.numericalFailures=info.numericalFailures+1; break; end
   rr=z.V-Vtarget;
   if abs(rr)<=p.forceTolerance
    st=z; info.ok=true; break;
   end
   if rr>0, right=mid; else, left=mid; end
   if right-left<p.slipTolerance, break; end
  end
  if info.ok, break; end
 end
 prev=cur; prevR=r; prevX=xs(i);
end
info.capacity=peak;
if info.ok
 st.forceResidual=abs(st.V-Vtarget); info.status='balanced';
elseif info.numericalFailures>0
 info.status='numerical_failure';
 info.message='An anchor solve did not converge; this is not classified as physical fatigue failure.';
elseif isfinite(peak)&&peak>=Vtarget
 info.status='branch_or_resolution_limit';
else
 info.message='No ascending force-balanced root was found within the specified crack-opening domain.';
end
end
