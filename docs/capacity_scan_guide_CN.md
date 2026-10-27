# capacity_scan.m：抗剪响应采样扫描

由本次上传的 cc19_critical.m 改名、简化。保留 function、p 参数结构、原算法和英文注释。它在当前初始历史上扫描一条加载路径，不是精确的全局承载力优化，也不是独立试验验证。

## 替换范围

下载 capacity_scan.m 和 fatigue_calculate.m。fatigue_calculate 仅有一处计算调用从 cc19_critical 改成 capacity_scan，未改循环推进等其他计算。当前根目录旧 cc19_critical.m 已移除，本地旧文件可删除；code20 和 original_20 保留历史接口。新入口运行时让根目录优先于 code20 位于 MATLAB 路径。

上传原文件调用旧 cc19_trial，本版接入已改名且前面验证等价的 trial。

## 四个步骤

1. 建立采样点。0～0.15 的 12 个点与 0～p.maxQ 的 p.scanPoints 个点合并；unique 删除重复值并排序。
2. for 循环逐点调用 trial。局部求解成功时逐列保存响应，并把 st.memory 传给下一点；失败时只存 q，力列保持 NaN，不更新历史。
3. 第二个 for 循环仅检查有限的 V，记录目前最大的 V 和对应 q。相同最大值保留第一次出现的位置，和原来的 max 相同。
4. 逐字段填充返回结构体。

这里保留了原扫描方式：若 p.maxQ 小于 0.15，近零采样序列仍可能包含大于 p.maxQ 的点。本次为了不改原算法，没有裁剪这些点，所以不能把输出无条件解释为严格限定在 [0,p.maxQ] 的最大值。

## 输出

| 字段 | 意义 |
|---|---|
| curve | 每行依次为 q、V、Vc、Vs、Vnsm |
| columns | 上述五列名称及单位 |
| sampledCapacity | 所有有效采样点中最大的总抗剪力 V，单位 N |
| qAtSampledPeak | 该采样点的裂缝竖向位移差，单位 mm |
| numericalFailures | localOK 为 false 的扫描点数 |
| status | sampled_model_domain_capacity 或 incomplete_capacity_scan |

如果没有有限的力结果，sampledCapacity 和 qAtSampledPeak 都是 NaN。只要存在局部求解失败点，状态为 incomplete_capacity_scan。未通过局部求解不等于材料已经破坏；FRP 局部或整根脱黏也不自动等于整梁失效。

V 是截面抗剪力，不是四点加载总荷载 Q；当前对称加载约定中 Q=2V。输出名称与数值均保留原样。

## 为什么要传 pathMemory

随着 q 增加，滑移最大值和筋失效记录可以发生变化。后一采样点继承前一个成功采样点的状态；不是每个点都从同一个完好状态独立计算。这个函数不会自行推进疲劳循环数。

## 简化了哪些语法

原来的整行拼接改为 curve(point,列号) 分别赋值；find 加索引 max 改为循环和 if；嵌套 struct 构造改为逐字段赋值。unique、linspace、NaN、isfinite 保留为基础函数，分别表示去重排序、等距取点、无有效数值、有限值判断。

## 验证

上传文件与 code20/cc19_critical.m 字节一致，以后者为基准。5 项完整扫描对比覆盖 strip、竖向 rod、无 FRP、maxQ 小于 0.15、强制进入备用局部迭代；另有 11 个短程疲劳工况对比，其中包含启用初始承载力扫描的工况。逐字段结果一致。这验证语法改写与调用同步，不证明采样峰值等于真实极限承载力。

复现：validation20/capacity_scan_check.m；日志：validation20/capacity_scan_*.log。

强制备用迭代的个别工况中新旧算法均出现矩阵奇异警告，结果仍一致；本次没有改变其数值处理。
