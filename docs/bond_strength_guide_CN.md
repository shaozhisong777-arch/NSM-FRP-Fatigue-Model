# bond_strength.m：局部黏结峰值退化

本文件由上传的 cc19_strength.m 改名、简化，保留 function、p 结构和原退化公式，注释为英文。

## 替换范围

一起下载根目录 bond_strength.m 和 trial.m。trial 中两处 cc19_strength 调用改为 bond_strength，其他计算不变。本次不用替换 read_and_calculate.m、fatigue_calculate.m、active_nodes.m、bond.m 或 anchorage.m。code20、original_20 的历史接口保持原样。使用新入口时，根目录应在 MATLAB 路径中优先于 code20。

## 函数接口

```matlab
tauM = bond_strength(p, localN);
```

localN 是各节点激活后累积的局部循环数，不是整梁统一的总循环数。输出 tauM 是相应节点当前的峰值黏结应力，保留输入数组的形状。它不是 FRP 筋的抗拉强度，也不是梁的总抗剪承载力。

## 循环怎样实现

先检查 localN 是实数数值数组，再逐节点检查是否有限且非负。第二个循环逐节点计算：

```matlab
cycles = max(localN(node), 1);
peakStress = p.tauM0 * (1 - p.bondFatigueK * log10(cycles));
tauM(node) = max(0, peakStress);
```

- node 是当前节点编号，numel(localN) 是节点数。
- max(localN(node),1) 使零循环或小于一次的循环采用 1，避免 log10(0)。
- log10 是以 10 为底的对数。
- 最后的 max 把负峰值截为零，不把它强行抬到残余应力 tauR。

输入参数合法时，循环数从 0 到 1 的峰值为 p.tauM0；之后随对数项变化。退化系数和初始峰值继续从 parameters 中读取，便于修改。

## 理论与调用

原代码注释将此退化式对应到所参考抗弯疲劳论文的式(2)，杆材系数 0.1965，条材 0.1985。本次沿用该式，未新增抗剪疲劳标定。active_nodes 判断本步哪些节点可以计数，fatigue_calculate 更新局部历史，trial 调用本函数获取退化峰值，锚固求解再通过 bond 使用该峰值。

## 验证

本次上传文件与 code20/cc19_strength.m 字节一致，使用后者作为基准。17 项直接对比检查覆盖 strip/rod、零与大循环数、行列向量/矩阵、空输入及非法输入错误标识；另进行 25 项响应/承载路径检查和 11 个短程疲劳工况检查。结果一致，验证的是改写等价性，不是试验准确性。

直接复现：validation20/bond_strength_check.m；日志见 validation20/bond_strength_*.log。
