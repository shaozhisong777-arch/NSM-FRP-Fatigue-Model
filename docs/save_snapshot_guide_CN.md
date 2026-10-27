# save_snapshot.m：整理计算快照

本函数由本次上传的 cc19_sample.m 改名、简化。保留 function、p 结构、英文注释。名称中的 save 表示把当前数据整理进返回的结构体，函数本身不写磁盘文件，也不修改疲劳历史或增加循环数。

## 需要替换的文件

下载 save_snapshot.m 和 fatigue_calculate.m。fatigue_calculate 仅将快照整理的一处调用从 cc19_sample 改成 save_snapshot。根目录的旧 cc19_sample.m 已移除；本地旧文件可以删除以免混淆，code20 和 original_20 中的历史版本保留用于追溯。trial、read_and_calculate 等其他文件本次不用替换。新入口使用时，根目录应在 MATLAB 路径中优先于 code20。

README 中较早的 crack_deformation 说明保留当时的同步记录；当前快照整理入口使用 save_snapshot。

## 接口

```matlab
v = save_snapshot(p, st, memory);
```

st 是某一荷载状态的计算结果，memory 是当前疲劳历史。省略第三个输入时，使用 st.memory。该函数只记录传入的一个状态；峰值、谷值以及循环次数 N 的完整快照由 fatigue_calculate 组织。

## 简化的四步

1. 用筋和锚固侧的循环统计有效节点总数，然后一次建立数据表，避免反复拼接。
2. 按筋、锚固侧、节点三层循环，用 rows(row,column) 逐项填写 12 列。
3. 用循环保留箍筋几何列，依次附加应变、应力和损伤。
4. 用 v.NSMfields、v.columns、v.steel、v.crack 逐个字段赋值，代替嵌套 struct 构造。裂缝分布继续调用 crack_deformation。

continue 表示跳过没有响应字段的筋。row 是总表行号，不是某一侧的局部节点号。数据顺序保持原来的“筋编号、侧编号、节点编号”。已有字段的失效筋仍记录，并在最后一列标记失效。

## NSMfields 的列含义

| 列 | 名称 | 含义 |
|---|---|---|
| 1 | bar | 筋编号 |
| 2 | side | 裂缝两侧的锚固侧编号 |
| 3 | x_mm | 该锚固侧的局部位置 |
| 4 | slip_mm | 当前滑移 |
| 5 | maxSlip_mm | 历史最大滑移 |
| 6 | bondStress_MPa | 当前黏结应力 |
| 7 | peakBondStress_MPa | 退化后的峰值黏结应力 |
| 8 | axialForce_N | 沿筋自身方向的轴力 |
| 9 | FRPstrain | FRP 应变 |
| 10 | localCycles | 节点局部循环数 |
| 11 | zone | 黏结阶段编号 |
| 12 | barFailed | 筋是否已经失效 |

steel 表保留 p.steel 原有列，末尾三列依次为箍筋应变、应力、疲劳损伤；当前 p.steel 的几何列由参数验证函数建立。crack 保存裂缝张开、滑移及位移差分布，不是梁挠度。

## 公式与验证

本文件主要整理已有结果，不新增力学公式，也不改变求解和失效条件。10 项直接检查覆盖不同节点数、空响应、无筋、无箍筋和省略 memory；另有 11 个短程疲劳工况逐字段对比，包括快照。结果与旧版一致。直接检查以 code20/cc19_sample 作基准，其裂缝函数已在上一轮验证与 crack_deformation 等价。

复现：validation20/save_snapshot_check.m；日志见 validation20/save_snapshot_*.log。
