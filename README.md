# NSM 抗剪疲劳模型（中文重组版）

## 下载

打开以下文件后，点击 GitHub 的 **Download raw / 下载原始文件**：

- [完整代码与中文文档包](downloads/NSM_shear_complete.zip)
- [仅 MATLAB 代码（13个文件）](downloads/NSM_shear_code_only.zip)
- [中文 Word 说明](docs/NSM_shear_manual_CN.docx)
- [中文 PPT（26页）](docs/NSM_shear_slides_CN.pptx)

也可点击仓库 **Code → Download ZIP** 下载整个仓库。

## 运行

仅将 `code/` 加入 MATLAB 路径。修改 `code/parameters.m` 中的参数，先运行 `report=verify_model()`，再运行 `main`。

`original_20/` 与 `reference_23/` 仅供追溯，请勿与新版运行文件一起加入 MATLAB 路径。

已在 GNU Octave 10.3.0 中完成数值检查；默认10000次循环的两次计算历史一致。尚未完成抗剪疲劳试验标定和商业 MATLAB 复测，不能将演示结果直接作为试验寿命预测。

详见 [完整中文使用说明](README_中文.md)。
