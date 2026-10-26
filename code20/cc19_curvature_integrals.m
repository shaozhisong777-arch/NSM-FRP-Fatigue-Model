function k = cc19_curvature_integrals(p, q)
    % 裂缝变形。输入q为裂缝竖向相对位移，不是跨中挠度。
    % 文件名保留，但这里只计算裂缝张开/滑移分布，不计算梁曲率或跨中挠度。
    y = linspace(0, p.crackHeight, 101)';
    g = (1 - y / p.crackHeight).^p.crackShapeExponent;
    w = q / p.kinematicDenominator;
    v = p.slidingRatio * w;
    k = struct('y', y, 'shape', g, 'opening', w * g, 'sliding', v * g, ...
               'verticalJump', q * g, 'horizontalJump', (-w * sin(p.theta) + v * cos(p.theta)) * g, ...
               'wMax', w, 'vMax', v, 'q', q);
end
