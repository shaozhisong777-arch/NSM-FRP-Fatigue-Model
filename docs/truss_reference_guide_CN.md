# shearfoce.m：均匀应变桁架对照

由上传的 cc19_shearforce.m 改名、简化，按用户指定拼写命名为 shearfoce.m。保留 function、p、英文注释及原公式。它不汇总混凝土与箍筋抗剪贡献，而是提供两个 FRP 抗剪对照值。

## 替换范围

下载根目录 shearfoce.m 和 cc19_paper_interpolation.m。后者保留名称和接口，只把实际调用改成 shearfoce，并使用英文注释；以后可单独整理其命名。fatigue_calculate、read_and_calculate、trial 本次不必替换。code20、original_20 保留历史文件；新入口运行时，让根目录在 MATLAB 路径中优先于 code20。

## 原公式

先由各根筋轴力计算应变 epsilon_i=T_i/(Ef*Af)，再求算术平均 epsilonMean。保留原来的全部 barForce 项，包括其中的零值，不另外剔除已失效筋。

桁架对照力：

Vref=nsmFaces*Af*Ef*epsilonMean*(crackHeight/nsmSpacing)*(cot(theta)+cot(alpha))*sin(alpha)。

代码用 1/tan 表示 cot。上传原代码注释将此桁架表达式关联到 2019 Single Crack 论文式(12)；本次只保留这一对照形式，不宣称它等同完整论文求解过程，也不把它作为新增的疲劳规律。

## 输出

- uniformStrainTrussReference_N：上述均匀应变桁架对照，单位 N。
- discreteIntersectionSum_N：直接记录输入 st.Vnsm，即主模型按实际交点筋计算的 FRP 竖向力之和。
- usedByStateSolver：false，表示该桁架对照不用于平衡求解。
- note：保留原文字说明。

主模型的 Vnsm 在 trial 中计算，按实际筋角度取竖向分量并考虑加固面数。实际交点求和后不能再重复乘 crackHeight/nsmSpacing 等计数因子。此处两个值可以不同，因为桁架对照采用均匀平均应变与连续数量近似，主模型使用离散交点和逐筋受力。

nBars=0 时对照力直接为零。FRP 筋的轴力方向沿筋本身，不能直接把任意倾角筋的轴力当成其竖向贡献。

## 简化语法

mean 改为 for 循环逐筋累加，再除以应变项数。保留原 barForce/(Ef*Af) 表达式与力公式乘除顺序，方便与旧结果比较。嵌套 struct 改为逐字段赋值。没有新增物理假定。

## 验证

上传文件与 code20/cc19_shearforce.m 字节一致，以后者为基准。17 项直接比较覆盖 strip/rod、60/90 度、行列轴力、零与非零轴力、无筋及包装函数输出。另有 11 个短程疲劳工况检查快照与结果。结果一致，验证改写等价性，并非该对照公式的试验准确性验证。

复现：validation20/truss_reference_check.m；日志见 validation20/truss_reference_*.log。
