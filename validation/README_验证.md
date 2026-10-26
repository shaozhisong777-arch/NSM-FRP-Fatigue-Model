# 验证记录

- verify_model.log：最终13文件版本的自包含验证，退出码0。
- regression_and_export.log：与原上传代码的短程相同输入回归；逐项最大差0；额外条/杆和超载导出，退出码0。
- main_default.log：默认main完成10000次循环并生成图像，退出码0。
- default_first_run.mat与examples/default内最终结果比较：503行历史完全一致。
- strip/rod/overload分别是短程条材、杆材和超模型域荷载导出检查。
- Octave的退出提示execution_exception未改变进程退出码，已验证MAT与CSV实际内容和PNG。
- 数值测试与原程序一致不代表原程序假设正确；尚未执行抗剪疲劳试验标定及商业MATLAB复测。
