function [tau, k, zone] = cc19_propagate(p, sMax, tauM)
    % 三段黏结包络。sMax为最大滑移历史；返回应力tau、割线刚度k和分段zone。
    %
    if any(sMax(:) < 0) || any(~isfinite(sMax(:)))
        error('cc19:slip', 'Invalid slip history.');
    end
    if isscalar(tauM)
        tauM = tauM * ones(size(sMax));
    end
    if ~isequal(size(tauM), size(sMax))
        error('cc19:slip', 'Bond arrays must have matching size.');
    end
    tauM = max(tauM, 0);
    % 当退化峰值低于原残余值时，避免出现“软化段反而增大”的倒挂包络。
    % 这是数值补充，不是原文给出的新的残余疲劳定律。
    tauR = min(p.tauR, tauM);
    tau = zeros(size(sMax));
    zone = ones(size(sMax));
    el = sMax <= p.deltaM;
    so = sMax > p.deltaM & sMax <= p.deltaU;
    re = sMax > p.deltaU;
    tau(el) = tauM(el) .* sMax(el) / p.deltaM;
    tau(so) = tauR(so) + (tauM(so) - tauR(so)) .* (p.deltaU - sMax(so)) / (p.deltaU - p.deltaM);
    tau(re) = tauR(re);
    zone(so) = 2;
    zone(re) = 3;
    k = tau ./ max(sMax, realmin);
    k(sMax == 0) = tauM(sMax == 0) / p.deltaM;
end
