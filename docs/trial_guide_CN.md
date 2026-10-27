# trial.m：给定裂缝位移时，各项剪力怎么计算

由本次上传的cc19_trial.m逐项整理，保留function格式、p结构、输入输出字段和计算关系，使用英文注释。这里给定q求剪力，不求全梁目标荷载对应的根；求根由state负责。

## 七个计算步骤

| 步骤 | 内容 | 说明 |
|---|---|---|
| 1 | 输入检查、裂缝运动学 | q是裂缝竖向相对位移，不是跨中挠度；通过cc19_curvature_integrals得到张开和滑移 |
| 2 | 混凝土贡献Vc | 沿用原经验闭合，并乘(1-Dc)；未改成2019论文PST/Green积分 |
| 3 | 箍筋贡献Vs | 每道实际相交箍筋逐项计算应变和应力；屈服上限及Ds达到1退出保持原样 |
| 4 | NSM锚固 | 对每根相交筋投影裂缝运动，按两侧局部龄期退化峰值，调用cc19_hard求锚固力 |
| 5 | 单根失效 | 保持优先顺序：完全锚固脱黏→FRP拉伸限值→用户保护层上限；已失效筋不恢复 |
| 6 | 剪力汇总 | Vnsm=面数×逐根竖向分力之和；V=Vc+Vs+Vnsm |
| 7 | 返回st | 逐字段赋值，保留原来的fields、memory、localOK等字段名与数据形状 |

## 当前公式（本次没有改变）

混凝土：

$$V_c=V_{c,amp}(1-e^{-q/q_0})[\rho+(1-\rho)e^{-w/w_0}](1-D_c)$$

箍筋：

$$\varepsilon_{s,j}=qg(y_j)/L_t,\quad\sigma_{s,j}=\min(E_s\varepsilon_{s,j},f_y),\quad V_s=\sum A_{s,j}\sigma_{s,j}$$

当钢筋损伤Ds达到1，代码令该道箍筋应力为零；Ds未到1时并不逐渐乘(1-Ds)降低应力。

NSM裂缝位移：

$$\delta_j=\max\left(0,qg(y_j)\frac{\sin(\theta+\alpha_j)-r\cos(\theta+\alpha_j)}{\cos\theta+r\sin\theta}\right)$$

竖向筋α=90°时，理论上化为δj=qg(yj)。为保留原结果与通用角度接口，本次仍保留一般式，没有改动参数文件的布置角。

NSM抗剪：

$$V_f=n_{faces}\sum_jT_j\sin\alpha_j$$

竖向筋的竖向分力等于筋自身轴力；nsmFaces只统计一次加固面数，不再另乘d/s。stirrupArea已包含一道箍筋的有效腿面积。

## 局部材料阶段与整根筋失效不同

弹性、软化、残余黏结分段由cc19_propagate与cc19_hard求解；同一时刻不同节点可能处于不同区。trial只读取这些局部结果，再判断该根筋是否按原规则整体退出。不把局部残余段直接等同于整梁破坏，也没有为了产生折点而添加新的阶段阈值。

## 原接口保留

```matlab
st = trial(p, q, memory, unload);
```

- p：校验后的参数与交点几何。
- q：当前试算的裂缝竖向位移。
- memory：已接受的局部循环、最大滑移、损伤和失效历史。
- unload：true表示按冻结的最大滑移历史卸载。
- st.memory：候选历史；只有外层疲劳程序接受平衡状态后，才成为已接受历史。

st保留q、w、v、Vc、Vs、Vnsm、V、barForce、steelStress、steelStrain、fields、memory、localOK、localForceResidual、forceResidual和unload。forceResidual先为NaN，由state与目标剪力比较后填写。

## 同时更新的调用文件

- state.m中两处cc19_trial改成trial。
- cc19_critical.m中一处承载扫描调用改成trial，补充英文注释；扫描算法不变。
- fatigue_calculate和read_and_calculate本次不需要改名或修改调用。

这三个更新文件应配套替换。根目录cc19_critical是供当前逐文件改名流程使用的版本；code20保留此前整套旧接口用于追溯。历史verify_2019还保留旧入口，后续整体整理时需要同步，不能将它对旧接口的检查当成新入口的完整测试。

## 实际核对

GNU Octave 10.3.0中：

- 25组直接检查，比较与本次上传原函数的全部输出字段：杆/条、竖向90°、零位移到较大位移、无NSM、无箍筋、已失效筋、钢筋损伤、混凝土损伤、极大局部龄期、拉伸/保护层上限、卸载、完整承载路径和非法q。
- 11组完整疲劳流程回归，历史、局部记忆、快照、峰谷状态和停止信息保持逐项一致。

记录见validation20/trial_direct_comparison.log和validation20/trial_integration_comparison.log。此检查验证写法改动的保真性，不是抗剪疲劳试验标定；商业MATLAB尚未复测。
