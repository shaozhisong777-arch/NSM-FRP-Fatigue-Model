# crack_deformation.m：裂缝变形分布

由上传的 cc19_curvature_integrals.m 改名、简化。原文件虽有 curvature 和 integrals 字样，实际不计算梁曲率、曲率积分或跨中挠度，因此改为 crack_deformation。保留 function、p 结构和英文注释。

## 文件替换

一起替换根目录 crack_deformation.m、trial.m、cc19_sample.m。trial 中一处、cc19_sample 中一处调用改名；后者除英文注释外，其余内容保持旧版。cc19_sample 暂不改名或重写，以后单独整理。code20 中的历史文件保留原样；使用新入口时让根目录优先于 code20 位于 MATLAB 路径。

## 计算关系

q 是裂缝竖向相对位移，不是跨中挠度。y 是沿裂缝高度的坐标，hc=p.crackHeight，m=p.crackShapeExponent。

- 形状函数 g(y)=(1-y/hc)^m。
- 张开尺度 w=q/p.kinematicDenominator。
- 滑移尺度 v=p.slidingRatio*w。
- 法向张开 opening=w*g。
- 切向滑移 sliding=v*g。
- 竖向位移差 verticalJump=q*g。
- 水平位移差 horizontalJump=(-w*sin(theta)+v*cos(theta))*g。

wMax、vMax、q 字段及原字段顺序都保留。在常用的非负单调形状假定下，wMax 和 vMax 对应分布的最大幅值。本函数本身不校验物理参数，沿用外部参数验证。

这些是原代码采用的指定裂缝变形关系，本次未将其替换为文献中完整的裂缝张开求解，也未新增剪切变形角或弯曲挠度结果。

## 简单语法

四个分布用 for 循环逐点计算，原来的嵌套 struct 构造改为逐字段赋值。linspace 表示等距取点，zeros 表示先建立零数组。形状函数保留原来的一行数组公式，保持原浮点计算次序；其中 `.^` 表示每个点分别乘方。该表达式逐标量计算时可能产生极小的舍入差，本版保留原表达式以便逐字段精确对比。

## 101 是什么

原函数沿高度取 101 个采样点，本次不改。它与锚固段每侧 24 个单元的 nCells 是不同的离散设置：一个用于裂缝高度上的分布输出，一个用于沿 FRP 筋锚固长度的求解。本文件自身没有给出 101 的论文依据，不能把它说成论文规定。

## 验证

上传原文件与 code20/cc19_curvature_integrals.m 字节一致。48 项直接对比覆盖不同形状指数、滑移比例与位移；另有 11 个短程疲劳工况对比，包含快照字段。结果一致，验证改写等价性，不代表物理假定已获得试验验证。

直接复现：validation20/crack_deformation_check.m；日志见 validation20/crack_deformation_*.log。
