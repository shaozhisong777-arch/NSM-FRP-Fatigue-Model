function [x, weights] = cc19_mesh(p, L)
    % 锚固网格。输入长度L；返回节点x和梯形积分权重weights。

    if ~isscalar(L) || ~isfinite(L) || L <= 0
        error('cc19:mesh', 'Anchor length must be positive.');
    end
    x = linspace(0, L, p.nCells + 1)';
    h = diff(x);
    weights = [h(1) / 2; (h(1:end - 1) + h(2:end)) / 2; h(end) / 2];
end
