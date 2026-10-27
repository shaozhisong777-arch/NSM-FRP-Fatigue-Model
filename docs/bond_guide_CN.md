# bond.m：逐节点计算三段黏结关系

由本次上传的 cc19_propagate.m 改名、简化，保留 function 格式、p 参数结构，注释改为英文。

## 如何替换

一起下载根目录 bond.m 和 anchorage.m。anchorage 中的 8 处 cc19_propagate 调用已同步为 bond。trial 不需要因本次改名再次修改。保留尚未改名的 code20 依赖，并让根目录在 MATLAB 路径中优先。历史 code20、original_20 文件保留，不会自动调用新函数。

## 输入和输出

```matlab
[tau, k, zone] = bond(p, sMax, tauM);
```

- p：参数结构；本文件用到 deltaM、deltaU 和 tauR。
- sMax：各节点的历史最大滑移，不是当前卸载滑移。
- tauM：当前退化后的峰值黏结应力，可为统一标量或与 sMax 同形的数组。
- tau：历史最大滑移在黏结包络上对应的应力。
- k：割线刚度，供锚固求解计算当前应力。
- zone：1 为弹性段，2 为软化段，3 为残余段。

当前卸载应力由 anchorage 使用 k 乘以当前滑移计算，不能把此处的 tau 直接当作任意卸载状态的应力。

## 循环的阅读顺序

1. 逐节点检查滑移是否为非负有限数。
2. 如果 tauM 只有一个数，循环把它填入每个节点；否则检查数组形状是否相同。
3. 建立与输入同形的输出数组。
4. 使用 `for node = 1:numel(sMax)`，逐个节点进入 if/elseif/else 分支。
5. 计算该节点的割线刚度；零滑移时使用初始斜率，避免除以零。

numel 是数组元素个数；sMax(node) 取出一个节点的数值。原来的 el、so、re 逻辑索引不再使用。

## 三个阶段及公式

记 s 为当前节点历史最大滑移，tm=max(tauM,0)，tr=min(p.tauR,tm)。

| 阶段 | 条件 | 包络应力 tau | zone |
|---|---|---|---|
| 弹性 | s ≤ deltaM | tm*s/deltaM | 1 |
| 软化 | deltaM < s ≤ deltaU | tr+(tm-tr)*(deltaU-s)/(deltaU-deltaM) | 2 |
| 残余 | s > deltaU | tr | 3 |

s=0 时 k=tm/deltaM；其余情况 k=tau/max(s,realmin)。realmin 是 MATLAB 极小正浮点数，保留原代码对极小滑移的保护。

tr=min(p.tauR,tm) 也是继承的数值补充：防止峰值退化到原残余值以下后，软化段变成上升段。它不是本次新增的试验标定规律。zone=3 仅表示局部节点处于残余段，不能单独等同整根筋失效。

本次没有修改公式、边界分段归属或失效准则。三段包络沿用原模型；疲劳退化后的 tauM 由外部传入，本文件不计算循环次数或疲劳寿命。

## 验证

GNU Octave 10.3.0 下，21 项直接对比检查覆盖分段边界、零与极小滑移、标量/节点峰值、退化峰值、行列向量/矩阵、空输入及错误标识；另进行 48 项锚固对比和 11 个短程疲劳工况对比。有效结果逐字段一致。这验证改写等价性，并非理论的试验验证。强制 Newton 回退的个别工况中新旧锚固求解均有矩阵奇异警告，处理方式保持原样。

复现直接检查：运行 validation20/bond_check.m；日志见 validation20/bond_*.log。
