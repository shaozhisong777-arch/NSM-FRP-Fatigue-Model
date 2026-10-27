> 历史记录：当前入口已按用户要求移除此运行时对照模块，见 [导出与清理说明](export_results_guide_CN.md)。

# paper_reference.m：快照中的论文对照入口

由上传的 cc19_paper_interpolation.m 改名。原文件不进行插值，因此名称改为 paper_reference，函数仍为一行调用：

```matlab
function a = paper_reference(p, st)
    % Return the shear reference used in the saved snapshot.
    % This function performs no interpolation or equilibrium calculation.
    a = shearfoce(p, st);
end
```

p 是参数结构，st 是当前响应，a 是 shearfoce 返回的对照结构体。保留用户指定的 shearfoce 拼写。函数没有逐节点计算，所以不添加无意义循环。

它只为快照提供统一的对照入口，既不增加力学公式，也不更新损伤、推进循环或参与平衡求解。实际对照公式在 shearfoce 中。为保持逐文件架构，本次保留这个很短的文件，不与其他模块合并。

一起替换 paper_reference.m 和 fatigue_calculate.m。fatigue_calculate 只将一处快照调用改为 paper_reference(p,peak)，snapshot.reference 字段及其他计算不变。根目录旧 cc19_paper_interpolation.m 可以删除，code20 和 original_20 的历史版本保留。其他文件不用替换。

17 项对照检查验证新入口与旧桁架参考输出一致；另运行一个 Nmax=1 的短程疲劳入口，逐个检查生成快照的 reference 与新函数输出一致。没有改变求解算法，本次不重复此前的全部长流程检查。

复现：validation20/truss_reference_check.m 和 validation20/paper_reference_check.m。日志：validation20/paper_reference_*.log。
