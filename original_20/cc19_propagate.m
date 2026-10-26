function [tau,k,zone] = cc19_propagate(p,sMax,tauM)
% 
if any(sMax(:)<0)||any(~isfinite(sMax(:))), error('cc19:slip','Invalid slip history.'); end
if isscalar(tauM), tauM=tauM*ones(size(sMax)); end
if ~isequal(size(tauM),size(sMax)), error('cc19:slip','Bond arrays must have matching size.'); end
tauM=max(tauM,p.tauR); tau=zeros(size(sMax)); zone=ones(size(sMax));
el=sMax<=p.deltaM; so=sMax>p.deltaM & sMax<=p.deltaU; re=sMax>p.deltaU;
tau(el)=tauM(el).*sMax(el)/p.deltaM;
tau(so)=p.tauR+(tauM(so)-p.tauR).*(p.deltaU-sMax(so))/(p.deltaU-p.deltaM);
tau(re)=p.tauR; zone(so)=2; zone(re)=3;
k=tau./max(sMax,realmin); k(sMax==0)=tauM(sMax==0)/p.deltaM;
end
