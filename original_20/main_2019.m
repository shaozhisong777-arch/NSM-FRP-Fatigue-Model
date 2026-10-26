% NSM加固抗剪疲劳版；旧文件名保留以方便对照，已不是抗弯模型。
% 本目录20个.m文件请整体使用，不能与旧抗弯文件混放。
clear; close all; clc;
here=fileparts(mfilename('fullpath')); addpath(here,'-begin');
report=verify_2019();
strengthened=ff19('strip',struct('outputDir',fullfile(here,'results_NSM_strip')));
% 同几何/同荷载的未加固对照；若一开始无平衡，表示此演示荷载超过对照模型承载域。
control=ff19('strip',struct('nsmEnabled',false, ...
 'outputDir',fullfile(here,'results_RC_control')));
% 杆材可选：rod=ff19('rod',struct('outputDir',fullfile(here,'results_NSM_rod')));
% 只改参数的推荐方法：p=cc19_parameters('strip'); p.Qmax=...; out=cc19_run(p);
