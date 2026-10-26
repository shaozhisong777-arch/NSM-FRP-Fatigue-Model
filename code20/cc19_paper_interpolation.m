function a = cc19_paper_interpolation(p, st)
    % 保留原接口并复用对照公式，不再存放重复公式。
    % 保留原文件和接口。内容与cc19_shearforce相同，直接调用以免两份公式改漏。
    % 这里只输出对照值，不参与全梁平衡求解。
    a = cc19_shearforce(p, st);
end
