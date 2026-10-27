# 本次18文件：中文审查与抗剪疲劳实现逻辑

**结论：程序能形成简化准静态抗剪疲劳计算链，但目前不能当作已验证的抗剪疲劳预测模型。** 网格对疲劳增量的影响、经验混凝土/裂缝关系、角度与输入校验问题需要先处理。

- [中文审查报告：逐文件、步骤、公式与文献](审查报告与公式_CN.md)
- [Word报告](抗剪疲劳代码审查与公式_CN.docx)
- [12页中文讲解PPT](抗剪疲劳逻辑与审查_CN.pptx)
- [整体逻辑图PNG](figures/抗剪疲劳实现逻辑.png) / [可缩放SVG](figures/抗剪疲劳实现逻辑.svg)
- [一次局部计算图PNG](figures/局部力学计算.png) / [可缩放SVG](figures/局部力学计算.svg)
- [18个文件调用图：draw.io、标准可编辑PPT与SVG](editable/README.md)
- [完全可编辑的两页逻辑图PPT](抗剪疲劳逻辑图_完全可编辑_CN.pptx)：节点、文字、公式与箭头都是原生对象；竖向16×24英寸画布，建议放大后编辑。
- [两张逻辑图PDF](抗剪疲劳逻辑图_CN.pdf)
- [完整运行摘要](results/完整运行摘要.md)
- [网格及活跃区补充](results/活跃区与细网格说明.md)
- [完整审查包ZIP](抗剪疲劳18文件审查包_CN.zip)

source/ 原样保存本次上传的18文件；[校验清单](source_manifest.csv)记录文件长度与SHA256。审查没有替你修改这些源码，也没有覆盖仓库根目录的工作版。未进入主链的 shearfoce 是你之前取消的对照模块，可删除；beam_load 是可选静力工具。

## 验证范围

GNU Octave 10.3.0；没有在MATLAB实际运行，没有新增试验标定。

- 原默认60°与改为90°各完整计算10000循环；都为runout，0根筋失效。
- 竖向筋100循环，每侧12/24/48/96/192/384单元的网格检查。
- 竖向筋24单元，循环块1/5/20/100的步长检查。
- 非法输入、角度覆盖、重复性、恒载、初始超载和初始用户限值检查。
- 初始峰谷、双侧平衡、滑移协调、黏结分段及竖向投影检查。
- Nmax=2短程导出：10张PNG、15个CSV与MAT读回一致。

## 复现

在MATLAB中打开checks/内相应脚本运行，或在Octave中执行脚本。所有脚本根据自身目录定位source/和results/，不依赖旧code20。检查会重新写results中的数据/MAT或导出目录，源码不改。

建议顺序：check_edges.m → check_invariants.m → check_convergence.m → check_mesh_fine.m → check_active_resolution.m → run_audit.m。完整两工况检查在本机合计约9分钟，其他机器时间不同；MATLAB本身尚未验证。

check_export.m使用Octave/gnuplot无界面绘图设置。若在MATLAB运行，删除graphics_toolkit('gnuplot')这一行；这里是移植提示，不是已完成MATLAB验证。Octave运行还需安装可用的gnuplot及中文字体；数值检查不依赖中文字体。

下载文件时在GitHub文件页点击 **Download raw**。Word/PPT/ZIP是二进制文件，网页预览不可用时直接下载。历史根目录说明对应逐次修改过程；本文件夹报告以这次上传的18文件为准。

## 编辑逻辑图PPT

打开“抗剪疲劳逻辑图_完全可编辑_CN.pptx”，单击节点修改文字，拖动形状调整位置；在“开始→选择→选择窗格”中按节点或箭头名称选择对象。公式是可编辑Unicode文本。箭头保留节点连接关系与自定义曲线路径；移动节点后检查回路线，可重新路由或编辑顶点。文件没有插入逻辑图图片。

两页分别为整体流程和局部力学计算；F编号对应审查报告。重建脚本为tools/build_editable_flow.py，依赖Graphviz及python-pptx。
