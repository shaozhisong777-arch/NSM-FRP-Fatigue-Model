# export_results.m：绘图与结果导出

由本次上传的 cc19_export.m 改名、简化。保留 function、p 参数结构，注释为英文。绘图、CSV、MAT 和状态输出仍集中在一个文件中；内部辅助函数不另拆文件。

## 本次清理

按用户要求取消运行时论文对照：删除当前根目录 paper_reference.m、shearfoce.m，并删除 fatigue_calculate 中的 snapshot.reference 赋值。主模型的混凝土、箍筋和实际 FRP 抗剪力保留，不删除 trial 中的 Vnsm 或 Vc+Vs+Vnsm。

参考论文作为写代码和公式说明的依据，不再额外计算桁架对照。参数和注释中的来源说明、status_and_sources.txt 中的文字元数据保留，它们不是对照模型计算。历史 code20、original_20 及历史文档保留作追溯，不代表新入口继续使用对照模块。

## 需要替换和删除

一起下载 export_results.m、read_and_calculate.m、fatigue_calculate.m。

- read_and_calculate：只把导出调用名及对应注释改为 export_results。
- fatigue_calculate：只删除 snapshot.reference = paper_reference(p,peak) 这一行。
- 本地当前工作目录的 paper_reference.m、shearfoce.m 可删除；如果还留着旧 truss_reference.m 或 cc19_paper_interpolation.m，也不再需要用于新入口。
- 不用替换其他已整理的计算模块。

新入口使用时，让根目录在 MATLAB 路径中优先于 code20。旧 cc19_export 可留在历史备份中，新入口不调用它。

## 接口与开关

```matlab
figs = export_results(out);
```

out 是 fatigue_calculate 返回的结果。makePlots=true 时绘图；exportResults=true 时写文件并保存提供/生成的图。两个开关独立：仅绘图不导出、仅导出表格不绘图、全部关闭都可使用。可选第二输入 figs 可提供已有图句柄，本函数不重复创建。

## 主要文件

- results_NSM_shear.mat：完整 out，已不含新计算快照的 reference 字段。
- history.csv：循环演化历史。
- initial_capacity.csv：初始承载扫描；关闭扫描时可以为空表。
- NSM_crossings.csv：实际筋交点和锚固长度。
- NSM_fields_N*.csv：各循环快照下每根筋、每个锚固侧的局部场。
- stirrups_N*.csv：箍筋交点、应变、应力、损伤。
- crack_N*.csv：沿高度的张开、滑移和位移差。
- NSM_failure_N*.csv：全部筋失效标记，包含后续没有局部场的筋。
- figure_*.png：本次生成或传入的图像。
- status_and_sources.txt：停止状态、残差、参数和来源文字说明。

## 图像

默认具备历史、承载扫描、FRP 与箍筋等数据时输出 10 个图窗：

1. 历史：抗剪力分量、裂缝位移、平衡残差三个子图。
2. 初始承载扫描。
3. 剪跨内几何、裂缝与实际交点筋。
4. 沿锚固段的滑移。
5. 沿锚固段的黏结应力。
6. FRP 应变分布。
7. 退化后的峰值黏结强度。
8. 节点局部循环数。
9. 裂缝张开和滑移分布。
10. 箍筋应力。

没有相应数据时会跳过部分图，不强制凑成 10 张。不同筋与锚固侧分别绘制，不跨筋连线。没有新增挠度、M–转角或剪切变形角图，因为当前模型没有求解这些量。

## 简化语法

CSV 改为“行循环 → 列循环 → 写一个数”，不用转置矩阵配合重复格式字符串；裂缝表和失效标志表改为逐节点/逐筋填列。绘图中的多列数据改为循环逐条曲线绘制。局部场选择改为明确的 if/elseif 分支，不再使用 profile.(field)。

figure、subplot、plot、fullfile、fprintf 等基础函数保留。onCleanup 保留用于函数正常结束或报错时关闭文件，避免遗留打开的文件句柄；它是文件清理工具，不是力学计算。

## 验证

短程计算与历史代码比较，去掉不再需要的 reference 字段后，历史、损伤、快照、承载扫描、最后状态及失效结果一致。以同一份 out 分别调用上传原导出函数与新函数，15 个 CSV 与状态文本逐字节一致；MAT 保存再读取与原 out 相同。在 Nmax=2、nCells=8 的短程检查中实际生成并保存 10 张 PNG（仅验证输出链路，不代表默认完整疲劳结果），另检查无平衡历史导出、两个开关关闭、传入图句柄，以及 read_and_calculate 的新入口写文件。

验证用 GNU Octave 10.3.0 与 gnuplot；MATLAB 的图像外观可能略有差别。没有为改变曲线形状而修改计算公式。

复现：validation20/export_results_check.m；日志：validation20/export_results_checks.log。
