function tauM = bond_strength(cfg,localN)
% 局部循环计数退化：继承参考代码，0.1965需用抗剪疲劳试验重新标定。
if ~isnumeric(localN)||~isreal(localN)||any(~isfinite(localN(:)))||any(localN(:)<0)
 error('cc19:history','Local cycles must be finite and nonnegative.'); end
tauM=max(cfg.bond_tau_res,cfg.bond_tau_max*(1-cfg.bond_fatigue_k*log10(max(localN,1))));
end
