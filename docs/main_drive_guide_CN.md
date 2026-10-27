# main_drive.m：主驱动脚本

按上传文件整理，保留主脚本格式，使用英文注释。具体计算继续由各个 function 完成，主脚本不放力学公式。

## 本次修改

原来的 `out = ff19(kind,options)` 改为 `out = read_and_calculate(kind,options)`。保留 clear、close all、clc 清理工作区和图窗，再将当前脚本所在目录加入路径并优先使用该目录的新函数。没有改变求解公式或参数默认值，也不必再次替换其他计算文件。

## 怎么运行

将 main_drive.m 与已更新的根目录函数放在同一文件夹，打开主脚本并点击 Run，或者命令窗口输入 main_drive。使用当前这套文件，不必为了运行新入口而另外调用历史 main_2019 或 ff19。

kind='strip' 选择条材；kind='rod' 选择杆材。

默认参数集中在 parameters.m。长期修改直接在参数文件里改；仅本次算例修改可在主脚本 options 中取消对应行开头的 %，例如：

```matlab
options.Nmax = 100;
options.alphaDeg = 90;
```

% 开头的行是注释，不执行。options 是本次运行的覆盖参数结构；p 是函数内部接收的完整参数结构，两者职责不同。read_and_calculate 先读取 parameters，再把 options 指定的值覆盖进去。

竖向筋角度应设置 alphaDeg=90。为遵循本轮不改默认参数的要求，默认 60 度仍保留；脚本提供了 90 度的注释示例，需按实际试件启用或直接修改 parameters。

## 结果

运行结束后在工作区查看 out。makePlots 和 exportResults 控制是否绘图及写文件，路径为 out.parameters.outputDir。新入口不计算或保存 snapshot.reference。

默认 Nmax=10000，达到上限只表示本次计算结束于设定循环数，不能直接当成疲劳破坏寿命。总荷载 Q 与剪跨剪力 V 的约定为 V=Q/2。

## 验证

使用主脚本内容进行短程检查，仅在测试副本中覆盖 Nmax=1、nCells=8、scanPoints=15，关闭绘图、导出和承载扫描。主脚本本身的默认值未改变。检查成功返回 out、存在历史结果、解析到当前目录的新函数且快照不含 reference。

复现：validation20/main_drive_check.m；日志：validation20/main_drive_check.log。本轮没有重新跑完整 10000 次计算。
