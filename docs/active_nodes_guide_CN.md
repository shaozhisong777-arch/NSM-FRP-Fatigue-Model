# active_nodes.m：疲劳活跃节点判断

由本次上传的 cc19_active.m 改名、简化。主函数保持 function 格式，参数使用 p 结构，代码注释为英文。同步替换根目录 active_nodes.m 和 fatigue_calculate.m；后者已调用新名称。本次不需要修改 bond.m、anchorage.m 或 trial.m。历史 code20 和 original_20 保留旧接口，不随本次改名切换。

## 它负责什么

本函数判断每根筋、每个锚固侧、每个节点是否可以在本步累积疲劳循环。它不修改 memory、不累加循环数，也不直接降低黏结强度。循环推进与历史更新在 fatigue_calculate 中，峰值退化在 cc19_strength 中。

```matlab
[active, amplitude] = active_nodes(p, peak, low, memory);
```

peak、low 是峰值和谷值荷载对应的响应；memory 保存失效标志和以前的激活记录。active 与 amplitude 都是 nBars×2 的 cell 数组，每个单元包含 nCells+1 个节点的列向量。这里的两侧是裂缝两边的锚固段。

## 简化后的顺序

1. 外层 for 遍历筋 bar，中层 for 遍历锚固侧 side。
2. 每一侧先把 active 设为 false，amplitude 设为零。
3. 荷载峰谷相等、筋已失效或峰/谷响应为空时，continue 跳过当前锚固侧。
4. 内层 for 遍历节点 node。
5. 计算非负峰谷滑移差，再分别检查历史激活记录、滑移阈值及循环滑移容差。

原来的数组逻辑运算 `|`、`&` 改为逐节点 if 判断，原来的单个长跳过条件拆成四个短判断。

## 原判断的准确含义

```matlab
slipRange = max(0, peakSlip - lowSlip);
activationSlip = p.activationFraction * p.deltaM;
```

一个节点本步活跃，需要同时满足：

- 它以前已激活，或者峰值响应的历史最大滑移严格大于 activationSlip；
- slipRange 严格大于 p.cyclicSlipTolerance。

等于阈值时不算超过，这与原代码一致。即使以前已激活，本步滑移差不足时也不会活跃。amplitude 保存的是完整峰谷差，没有除以 2；本次保留原字段名和数值含义。若峰值滑移小于谷值滑移，差值截为零，不改成绝对值。

`active{bar,side}(node)` 表示“第 bar 根筋、第 side 个锚固侧、第 node 个节点”的本步活跃标志。cell 花括号用于取出某侧节点数组，后面的小括号用于读取该数组中的一个节点。

## 理论范围

滑移阈值的形式沿用原疲劳模型；activationFraction 是参数文件设置的比例，不能把本函数理解为普适的抗剪疲劳定律。保留历史激活记录与非零峰谷滑移差门槛也沿用原代码。本次只简化语法，不新增物理公式或试验标定。

## 验证

本次上传文件与 code20/cc19_active.m 字节一致，以后者作比较基准。8 项直接检查覆盖激活历史、阈值等号、循环容差等号、零或反向滑移差、恒载、失效筋、缺失响应和无筋情况。另有 11 个短程疲劳工况对比。检查对比 active、amplitude 及疲劳流程输出，验证改写等价性，不表示模型已经完成试验验证。

复现直接检查：validation20/active_nodes_check.m；结果日志：validation20/active_nodes_*.log。
