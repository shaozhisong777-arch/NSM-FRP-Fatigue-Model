% 主驱动：只计算一个算例；参数在cc19_parameters.m中修改。
% 第一次使用或修改公式后，可先单独运行 report = verify_2019();
clear;
close all;
clc;
here = fileparts(mfilename('fullpath'));
addpath(here, '-begin');
kind = 'strip'; % 'strip'条材 / 'rod'杆材
options = struct();
% options.Nmax = 100; % 调试时使用；默认仍为10000次
% options.Qmax = 165000; % 单位N，总加载力；剪跨内V=Qmax/2
out = ff19(kind, options);
% 结果保存在out及其parameters.outputDir；达到Nmax不代表已经发生疲劳破坏。
% 未加固对照需选择共同能承受的荷载，例如双方均用Qmax=110000。
