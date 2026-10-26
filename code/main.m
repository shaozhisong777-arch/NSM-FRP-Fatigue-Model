% MAIN 抗剪疲劳主驱动。所有物理默认参数请在parameters.m中修改。
% 打开本目录后运行 main；也可直接调用 out=run_model('strip')。
clear; close all; clc;
here=fileparts(mfilename('fullpath')); addpath(here,'-begin');
kind='strip';                       % 'strip'条材 / 'rod'杆材
options=struct();                   % 可选：仅覆盖本算例参数，不修改默认文件
% options.N_max=100;                % 调试时缩短循环；正式计算删除此覆盖值
% options.act_ratio=0.10;           % 仅机制演示，不能用来宣称材料已标定
out=run_model(kind,options);
% 未加固对照需显式运行；默认总荷载可能超出未加固模型承载域：
% control=run_model(kind,struct('nsm_on',false,'output_dir',fullfile(here,'results_control')));
% 重复性和力平衡检验请独立运行：report=verify_model();
