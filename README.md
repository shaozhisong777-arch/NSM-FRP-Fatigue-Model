# NSM抗剪疲劳：原20文件逐文件简化版（当前v2）

本版按用户要求，以原始20文件逐个修改，文件名和主要接口不变，不再采用上一版13文件重组。

## 逐文件改名与新手版（进行中）

- [parameters.m](parameters.m)：保留p结构，英文注释。
- [read_and_calculate.m](read_and_calculate.m)：统一入口，已调用fatigue_calculate。
- [fatigue_calculate.m](fatigue_calculate.m)：本次上传cc19_run的简单语法改写；不另加计算模块文件。
- [state.m](state.m)：原cc19_state求根器，单文件四步；[中文说明](docs/state_guide_CN.md)。
- [trial.m](trial.m)：各项抗剪响应的逐项计算；[中文说明](docs/trial_guide_CN.md)。初始承载扫描需配套使用根目录[cc19_critical.m](cc19_critical.m)。
- [anchorage.m](anchorage.m)：双侧锚固求解，矩阵组装和软化判断改成循环；需配套更新 trial.m；[中文说明](docs/anchorage_guide_CN.md)。
- [bond.m](bond.m)：三段黏结关系，逐节点循环判断；需同步更新 anchorage.m；[中文说明](docs/bond_guide_CN.md)。
- [active_nodes.m](active_nodes.m)：逐筋、逐侧、逐节点判断疲劳活跃状态；需同步更新 fatigue_calculate.m；[中文说明](docs/active_nodes_guide_CN.md)。
- [bond_strength.m](bond_strength.m)：逐节点计算退化峰值；需同步更新 trial.m；[中文说明](docs/bond_strength_guide_CN.md)。
- [anchor_mesh.m](anchor_mesh.m)：锚固网格与积分权重，避免与 MATLAB 的 mesh 绘图函数重名；需同步更新 anchorage.m；[中文说明及24单元的含义](docs/anchor_mesh_guide_CN.md)。
- [crack_deformation.m](crack_deformation.m)：裂缝张开/滑移分布；需同步更新 trial.m 与根目录 cc19_sample.m；[中文说明](docs/crack_deformation_guide_CN.md)。
- [该文件的论文公式对应表与中文语法说明](docs/fatigue_calculate_guide_CN.md)。

这些已改名文件与尚未改名的其余code20依赖配合使用。下方完整20文件包保留整套旧接口用于追溯；当前逐文件改名版本请使用上述文件。

## 下载

- [最新完整20文件代码、中文说明与示例](downloads/NSM_20files_complete.zip)
- [仅20个MATLAB源文件](downloads/NSM_20files_code_only.zip)
- [中文Word：20文件使用说明](docs/NSM_20files_manual_CN.docx)
- [中文PPT：25页](docs/NSM_20files_slides_CN.pptx)

打开文件页后点击 **Download raw**；也可 Code → Download ZIP 下载仓库。

## 使用

只把 `code20/` 加入MATLAB路径，修改 `cc19_parameters.m`，先运行 `report=verify_2019()`，再运行 `main_2019`。默认输出10张图及对应场数据。详细阅读 [新版中文说明](README_20_CN.md)。

默认10000次的两次结果一致，力平衡、原接口回归和导出已在Octave验证。没有在商业MATLAB复测，也没有做抗剪疲劳试验标定。原模型未实现2019抗剪论文式(7)的完整PST/Green函数裂缝张开积分；本次没有用排版简化掩盖该限制。

`code/`、`README_中文.md`及根目录旧中文Word/PPT属于上一版13文件方案，保留供追溯，不作为本版运行入口。`original_20/`保持上传原文件不变，`reference_23/`为参考。
