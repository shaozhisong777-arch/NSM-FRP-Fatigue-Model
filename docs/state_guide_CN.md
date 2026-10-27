# state.m：一个文件中的四个计算步骤

本版根据用户上传的cc19_state.m整理，文件名和函数名为state，仍是function格式，p参数结构、五个输入与st/info输出不变，英文注释。二分求根是本文件底部的局部函数，没有增加state1、state2、state3等额外模块。

## 为什么不按曲线外观拆成三个整梁物理阶段

state负责整梁剪力平衡求根：

$$R(q)=V_c(q)+V_s(q)+V_f(q)-V_{target}=0$$

同一根梁、同一个循环中，不同NSM筋及不同锚固节点可以分别处于弹性、软化、残余黏结状态；还可能同时有未屈服/屈服箍筋或已退出的NSM。没有当前模型依据支持把整梁统一切成“state1全弹性、state2全软化、state3全脱黏”，也不能用任意荷载比例或循环数人为插入折点。

## 当前state内部四步

| 步骤 | 代码做什么 | 公式或判据 |
|---|---|---|
| 1. 输入、限值与搜索域 | 初始化info；检查用户压杆/抗弯上限；区分加载和卸载 | 加载：q在[max(0,previousQ),maxQ]；卸载：q在[0,max(previousQ,slipTolerance)] |
| 2. 扫描 | 用同一份memory逐点调用cc19_trial；找到上升支变号区间 | R(left)<0且R(right)>0；若某点直接满足力残差也可立即接受 |
| 3. 二分 | 调用本文件内bisect_interval，不需要额外.m文件 | middle=(left+right)/2；R(middle)>0则缩右端，否则缩左端 |
| 4. 结果分类 | 返回平衡状态或具体诊断 | 成功要求abs(R)<=forceTolerance；区间变小本身不代表成功 |

节点力学、本构、局部破坏没有搬进state。每次试算仍由cc19_trial及其依赖计算，试算时不提交memory；疲劳循环接受求解结果后才更新历史。

## 真正的局部黏结阶段在哪里

| 局部状态 | 原有条件 | 当前处理位置 |
|---|---|---|
| 弹性黏结段 | 历史最大滑移H<=deltaM | cc19_propagate |
| 软化段 | deltaM<H<=deltaU | cc19_propagate |
| 残余黏结段 | H>deltaU | cc19_propagate |
| 整根NSM退出 | 代码规定的完全锚固脱黏、FRP拉伸上限或保护层上限 | cc19_hard、cc19_trial |

局部残余段不自动等于整根完全脱黏。后续如需画阶段演化，应按每根筋/每侧/每节点的zone及失效标志统计，而不是在全梁求根器中人为划分三个区间。

## 保留原判定，避免把数值问题画成材料阶段

- balanced：找到满足剪力残差的解。
- numerical_failure：至少存在失败的局部锚固求解，且未找到合格根；不等于材料破坏。
- branch_or_resolution_limit：扫描值达到目标附近，但没有找到合格的允许上升支根。
- no_equilibrium_in_model_domain：当前指定q域内未找到合格根，受搜索范围、离散与模型闭合影响。
- user_concrete_strut_limit / user_flexural_limit：触发用户给定上限。
- opening_limit_reached：加载的允许q区间为空。

info.capacity保留原字段名，值是“停止扫描前有效扫描点的最大剪力”，不包含所有二分点，也不是精确全局承载力。

## 同步调用

fatigue_calculate.m中的四处调用已从cc19_state改为state。入口仍是：

```matlab
out = read_and_calculate('strip');
```

需同时下载state.m和更新后的fatigue_calculate.m，其余尚未改名的依赖仍保留原名。code20历史版本仍保留完整旧接口，供对照。

## 验证

- 11组完整疲劳流程与上传原版对比，包含杆/条、局部退化、零荷载幅、无NSM、可选Miner、初始超载、承载扫描、步长减半和模型域失衡；历史、记忆、快照及状态逐项一致。
- 10组求根边界对照：线性根、双根曲线的首个上升支根、跳跃无根、全部局部失败、二分中局部失败、卸载、两种用户限值、空搜索域、区间过小但残差未达标。使用人为函数检验数值行为，不是材料试验验证。
- 检查在GNU Octave 10.3.0执行；商业MATLAB尚未复测。没有为制造阶段变化而改动材料关系或强行给曲线加折点。

记录见validation20/state_solver_comparison.log与validation20/state_integration_comparison.log。
