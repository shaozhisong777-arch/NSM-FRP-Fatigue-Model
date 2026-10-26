function tauM = cc19_strength(p,localN)
% debonding process
if ~isnumeric(localN)||~isreal(localN)||any(~isfinite(localN(:)))||any(localN(:)<0)
 error('cc19:history','Local cycles must be finite and nonnegative.'); end
tauM=max(p.tauR,p.tauM0*(1-p.bondFatigueK*log10(max(localN,1))));
end
