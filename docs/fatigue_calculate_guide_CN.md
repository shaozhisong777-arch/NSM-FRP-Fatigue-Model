# fatigue_calculate：论文依据与新手阅读说明

[查看逐步流程图与全部公式](fatigue_workflow_formulas_CN.md)。

本文件由用户这次上传的 `cc19_run.m` 改写，名称为 `fatigue_calculate.m`，仍然是 `function out = fatigue_calculate(p)`。英文代码注释与中文解释分开保存。原始上传文件不改写；历史版 `code20/cc19_run.m` 保留供对照。

## 先理解它负责什么

它是疲劳计算的“调度主循环”，并不是在一个文件里实现了全部抗剪理论。主流程是：

1. 检查参数，初始化各根筋、各锚固侧、各节点的历史。
2. 求首次最大荷载和最小荷载下的平衡。
3. 找到发生实际滑移循环、满足激活条件的节点。
4. 给这些节点增加候选局部循环数；必要时更新可选Miner损伤。
5. 用候选损伤重新求峰谷平衡，成功才接受；不成功时先缩小循环步长。
6. 保存已接受的状态，到设定循环上限或明确停止条件时返回。

**当前模型组合是“静力抗剪平衡＋移植的界面疲劳退化＋原有闭合假设”，不是一套已经完成抗剪疲劳试验标定的完整理论。**

## 哪些计算来自哪篇论文

| 计算或操作 | 代码位置 | 文献对应 | 需要区分的地方 |
|---|---|---|---|
| 节点局部龄期增加 `localN += cycleBlock` | 本文件 `update_memory`，以及 `cc19_active` | Chen、Wang、Cheng，2019抗弯疲劳论文，式(2)、第2.8节流程 | 局部计数思想有依据；移植到裂缝两侧NSM抗剪模型是改编 |
| 黏结峰值 `tauM=max(0,tau0*(1-k*log10(max(localN,1))))` | 外部 `cc19_strength.m`，由状态试算调用；不直接写在主循环里 | 同一疲劳论文PDF第4页、期刊第177页式(2) | 杆材k=0.1965、条材k=0.1985；`max(localN,1)`用于首循环/未激活时的数值初始化 |
| 滑移超过 `0.75*deltaM` 才激活 | 外部 `cc19_active.m` | 同一论文式(2)后的阈值说明 | 代码另外加入“峰谷滑移幅非零”、单筋失效后不计数等判断；这些是当前循环实现的补充 |
| 最大/最小荷载下 `Vtarget=Q/2` | 本文件对 `state` 的调用 | 对称四点加载的静力平衡 | Q为两个加载点的总力；不是疲劳退化公式，也不适用于所有加载方式 |
| `V=Vc+Vs+Vnsm`、相交筋的贡献 | 外部 `state`、`cc19_trial` | 2022裂缝效应论文式(9a)-(9d)；2024 ECC-FRP论文式(1)给出相应分解原则 | 本版是离散NSM条/杆，不能把ECC覆盖层贡献不加区分地套用；求根还需要额外本构和运动学闭合 |
| 两侧滑移和与轴力协调 | 外部 `cc19_hard` | Chen和Cheng，2019单裂缝抗剪论文，式(9d)、(11) | 保留有限锚固离散求解，不代表完整复现该论文所有方程 |
| 钢筋 `Nf=Nref*(stressRef/stressRange)^m`，`D+=dN/Nf` | 本文件 `update_memory` 可选钢筋段 | 通用幂律S-N与线性Miner累计思想；是原代码附加接口 | **不是所提供两篇2019论文直接给出的抗剪疲劳公式**；默认Nref=Inf关闭，无标定数据不应随意开启 |
| 混凝土S-N/Miner及等效应力范围 | 本文件 `update_memory` 可选混凝土段 | 原代码附加假设 | 用Vc包络在41个q点上的极差除以width*ds，是模型选择，不是2019论文的混凝土疲劳定律 |
| 经验 `Vc(q,w)` | 外部 `cc19_trial`；本文件在混凝土S-N中重复采样该关系 | 原20文件的经验闭合关系 | 不是2019单裂缝论文式(7)的PST/Green函数积分；本次没有替换它 |
| 步长减半、限制q增量、保存快照 | 本文件主流程 | 数值计算与数据保存 | 没有对应的材料计算公式；不是物理阶段转换标准 |
| 失衡停止 | 本文件处理 `info.status` | 借鉴疲劳论文第2.7节的失衡终止思想 | 论文是其式(13)的脱黏长度Ld无解；本代码是指定q域内的剪力根/用户限值判断，二者不是同一判据。数值不收敛也不等于物理破坏 |

### 论文完整名称

1. **Chen, Wang and Cheng (2019)**, *Modeling NSM FRP strengthened RC beams under fatigue due to IC-debonding*. International Journal of Fatigue 126, 174–187. DOI: [10.1016/j.ijfatigue.2019.04.039](https://doi.org/10.1016/j.ijfatigue.2019.04.039)。它验证的是抗弯IC脱黏疲劳。
2. **Chen and Cheng (2019)**, *Single Crack–Based Model for FRP Shear-Strengthened RC Beams*. DOI: [10.1061/(ASCE)CC.1943-5614.0000953](https://doi.org/10.1061/(ASCE)CC.1943-5614.0000953)。它是静力抗剪模型；完整PST/Green函数裂缝张开方程目前仍未实现。
3. **Chen et al. (2022)**, *FRP Shear-Strengthened RC Beams: Re-examining the Shear-Crack Effect*. DOI: [10.1061/(ASCE)CC.1943-5614.0001251](https://doi.org/10.1061/(ASCE)CC.1943-5614.0001251)。用于理解交点应力及剪力分担原则。
4. **Chen et al. (2024)**, *Shear Resisting Mechanisms of ECC FRP Strengthened RC Beams*. DOI: [10.1061/JCCOF2.CCENG-4395](https://doi.org/10.1061/JCCOF2.CCENG-4395)。用于理解拉/剪应力投影和相互作用；本版不直接模拟ECC覆盖层。

## 为什么原代码看起来难

难点不全在公式，而是把四类内容放在了一起：结果结构初始化、循环控制、带记忆的候选损伤、输出整理。尤其是这一行同时使用元胞、逻辑筛选和数组运算：

```matlab
proposed.age{j,s}(activeNodes{j,s}) = ...
    memory.age{j,s}(activeNodes{j,s}) + cycleBlock;
```

新版改成逐节点普通循环：

```matlab
for bar = 1:p.nBars
    for side = 1:2
        for node = 1:p.nCells + 1
            if activeNodes{bar,side}(node)
                proposed.age{bar,side}(node) = ...
                    memory.age{bar,side}(node) + cycleBlock;
            end
        end
    end
end
```

含义就是：“每根筋有两个锚固侧；每侧逐节点看，只给活跃节点增加循环数。”代码行数变多，但不用在一行里读懂多种索引语法。

## 新版具体简化了哪些语法

- 长的 `struct(...)` 构造改成 `out.status=...` 等逐字段赋值。
- 活跃节点的布尔向量赋值改成逐节点 `for`＋`if`。
- 可选钢筋损伤改成逐根箍筋计算；可选混凝土包络改成逐点计算。
- 下一快照查找改成顺序循环；循环块限制分为两次简单 `min`。
- 复杂短路判断拆成有名称的布尔变量。
- 16列历史改成 `row(1)=...` 至 `row(16)=...`，列义保持不变。
- 初始化、候选损伤、历史行和快照放在**同一个.m文件底部的局部函数**，没有增加独立计算模块文件。
- 保留必要的步长回退、不可逆历史、峰谷检查和停止状态；没有删除可选S-N接口或改成必定通过的固定循环。

## 仍然需要认识的MATLAB语法

| 写法 | 含义 |
|---|---|
| `p.Qmax` | 结构体p中的最大荷载参数 |
| `memory.age{bar,side}` | 取出某根筋、某个锚固侧的节点龄期数组 |
| `memory.age{bar,side}(node)` | 取出该数组第node个数值 |
| `[peak,info]=state(...)` | 同时接收状态和求解说明两个输出 |
| `~info.ok` | 求解没有成功 |
| `&&`、`||` | 两个条件同时成立／至少一个成立 |
| `out.history(end+1,:)` | 在历史表末尾追加一行，冒号表示全部列 |
| `Inf`、`NaN` | 无穷大／未定义数值；默认Inf用于关闭可选S-N接口，未发生失效时failureCycle为NaN |

## 调用方法

```matlab
p = parameters('strip');
out = fatigue_calculate(p);
```

或用已同步更新的入口：

```matlab
out = read_and_calculate('strip');
```

本文件仍依赖剩余原名模块，例如cc19_validate、state、cc19_active等。把parameters、read_and_calculate、fatigue_calculate放在同一目录，并保留这些依赖；不要误把只下载这一个文件理解为已包含全部求解器。

## 数值核对

在GNU Octave中，将新版与本次上传的cc19_run逐案比较，保留同一参数与外部依赖，检查历史表、局部记忆、全部快照、初始承载路径、末次峰谷状态及停止信息。检查结果见 `validation20/fatigue_calculate_comparison.log`。这些检查证明写法改动的保真程度，不证明剪切疲劳理论已经由试验验证。
