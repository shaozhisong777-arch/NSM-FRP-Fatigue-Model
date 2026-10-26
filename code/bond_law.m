function [tau,k,zone] = bond_law(cfg,sMax,tauM)
% 三段包络与割线卸载刚度：弹性、软化、残余；zone=1/2/3。
if any(sMax(:)<0)||any(~isfinite(sMax(:))), error('cc19:slip','Invalid slip history.'); end
if isscalar(tauM), tauM=tauM*ones(size(sMax)); end
if ~isequal(size(tauM),size(sMax)), error('cc19:slip','Bond arrays must have matching size.'); end
tauM=max(tauM,cfg.bond_tau_res); tau=zeros(size(sMax)); zone=ones(size(sMax));
el=sMax<=cfg.bond_slip_max; so=sMax>cfg.bond_slip_max & sMax<=cfg.bond_slip_ult; re=sMax>cfg.bond_slip_ult;
tau(el)=tauM(el).*sMax(el)/cfg.bond_slip_max;
tau(so)=cfg.bond_tau_res+(tauM(so)-cfg.bond_tau_res).*(cfg.bond_slip_ult-sMax(so))/(cfg.bond_slip_ult-cfg.bond_slip_max);
tau(re)=cfg.bond_tau_res; zone(so)=2; zone(re)=3;
k=tau./max(sMax,realmin); k(sMax==0)=tauM(sMax==0)/cfg.bond_slip_max;
end
