# 根据本次公式截图重画的抗剪疲劳计算逻辑

图中F/S/E前缀分别表示三篇不同论文；同一个式号不能跨论文混用。流程描述当前代码实际采用或按原理改写的关系，源码未修改。

- [可编辑PPT，3页](公式对应版_抗剪疲劳计算逻辑_可编辑.pptx)
- [可编辑draw.io，3页](公式对应版_抗剪疲劳计算逻辑_可编辑.drawio)
- [图1：抗剪疲劳主循环](公式对应版｜抗剪疲劳主循环.png)
- [图2：公式与抗剪平衡内部求解](公式对应版｜抗剪平衡内部求解.png)
- [图3：公式采用范围与当前实现](公式采用范围与当前实现.png)

GitHub文件页点击Download raw下载。draw.io用 https://app.diagrams.net/ 的“文件→从设备打开”编辑。PPT的框、文字、公式及分段箭头均为原生对象，不是图片；公式为可编辑文本。回路的中间线段可以独立移动。

## 公式对照

| 截图来源与公式 | 本流程处理 | 对应代码 |
|---|---|---|
| F式(1)：三段黏结包络 | 采用其包络形式，标明残余截断和历史割线的代码补充 | bond |
| F式(2)：局部峰值退化 | 采用杆0.1965、条0.1985；零龄期与负峰值按代码处理 | bond_strength |
| F式(9b)：解析系数矩阵 | 当前未直接实现；代码迭代中的A*u=b是不同的离散组装系统 | anchorage |
| F式(10)：沿筋积分黏结应力求轴力 | 按每根筋的局部锚固段坐标改写上下限，不直接保留梁半跨L0/2 | anchorage |
| F式(11a,b)、(13a,b)：Ps/Pd与半跨软化/脱黏长度 | 当前未采用；属于原纵向加固抗弯模型，不能直接当当前抗剪总荷载和锚固段关系 | 无对应已实现计算 |
| F式(14a–c)：弯曲挠度 | 当前未采用；竖向NSM筋不直接沿用该纵向偏心加固关系 | 无挠度求解模块 |
| S式(9a–c)：分段解析滑移解 | 当前未直接采用；数值离散的双侧锚固并非其解析公式逐式实现 | anchorage |
| S式(9d)、(11)：两侧滑移和与交点应变连续 | 用于解释双侧协调；同一根筋EfAf相同，交点力相等 | anchorage |
| S式(10)：黏结应力积分求筋应变 | 支持当前局部应力积分与T/(EfAf)应变的计算原理 | anchorage |
| E式(1)：总抗剪贡献分解 | 采用总平衡思想，当前第三项改为离散NSM筋竖向贡献Vf | trial / state |
| E式(2)：ECC-FRP的法向与切向贡献 | 当前未采用；ECC连续覆盖层与本模型NSM筋不同 | 无ECC覆盖层模块 |

混凝土经验Vc、指定裂缝g和v/w、箍筋传力长度ls是当前代码附加假定；已在图2的相应节点标明。不能把这些内容都标为上述论文原公式。q是裂缝竖向位移差；本程序裂缝法向开口w与F文中的梁挠度w不是同一物理量。

截图中的cc19_validate、cc19_critical是旧名；当前分别为prepare_parameters、capacity_scan。截图中参数校验和初始化代码本身并不等于实现了F式(2)，真正退化公式在bond_strength内。

F：Chen, Wang & Cheng (2019), Modeling NSM FRP strengthened RC beams under fatigue due to IC-debonding，DOI 10.1016/j.ijfatigue.2019.04.039。

S：Chen & Cheng (2019), Single Crack–Based Model for FRP Shear-Strengthened RC Beams，DOI 10.1061/(ASCE)CC.1943-5614.0000953。

E：Chen等(2024), Shear Resisting Mechanisms of ECC FRP Strengthened RC Beams，DOI 10.1061/JCCOF2.CCENG-4395。

图2中箍筋应力上限与逐筋求和还注明R22背景：FRP Shear-Strengthened RC Beams: Re-examining the Shear-Crack Effect，DOI 10.1061/(ASCE)CC.1943-5614.0001251。
