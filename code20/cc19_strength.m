function tauM = cc19_strength(p, localN)
    % 局部疲劳峰值。localN是节点激活后的循环数，不是整梁所有节点共同的循环数。
    % 疲劳论文式(2)：杆材0.1965、条材0.1985；负值取零，不能强行限制在tauR以上。
    if ~isnumeric(localN) || ~isreal(localN) || any(~isfinite(localN(:))) || any(localN(:) < 0)
        error('cc19:history', 'Local cycles must be finite and nonnegative.');
    end
    tauM = max(0, p.tauM0 * (1 - p.bondFatigueK * log10(max(localN, 1))));
end
