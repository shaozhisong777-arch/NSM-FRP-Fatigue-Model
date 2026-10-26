% 公共参数脚本：数值只在本文件修改，setup_model会在函数内部加载。
% 单位：N、mm、MPa；Q_max/Q_min为对称四点加载总荷载，剪跨V=Q/2。
% 本模型为NSM条/杆，不是ECC-FRP覆盖层模型；疲劳和混凝土闭合关系待试验标定。
% 脚本也可直接运行查看变量；函数调用请用 run_model 或 setup_model。

if ~exist('kind','var') || isempty(kind), kind = 'strip'; end
kind = lower(char(kind));
if ~any(strcmp(kind,{'rod','strip'})), error('cc19:input','kind must be rod or strip.'); end

con_width = 180; % mm
con_depth = 400; % mm
con_flange_width = 450; % mm
con_flange_depth = 100; % mm
con_fc = 39.7; % Mpa
con_E = 30000; % Mpa
steel_depth = 360; % mm
shear_span = 900; % mm
span = 2400; % mm     
crack_height = 300; % mm
crack_x = 100;% mm
crack_angle = 28.21; % deg，沿用原默认值；应由裂缝观测确定，非所附论文公式(2a)
slide_ratio = 0.20;                % v/w，
crack_exp = 1;             % g(y)=(1-y/hc)^exponent

% values for NSM strip 
frp_E = 170900; % Mpa
frp_area = 1.4*9.5; % mm^2
frp_perim = 2*(1.4+9.5); % mm
frp_angle = 60; 
nsm_spacing = 243; % mm
nsm_first_x = 121.5; % location for the first nsm
nsm_y_bot = 15; 
nsm_y_top = 300; 
nsm_faces = 2; % two sides
nsm_segments = [];  % [x_bottom,y_bottom,x_top,y_top] only one side
nsm_on = true;
frp_fu = 2500; % Mpa   experimental work value    
cover_cap = Inf;    

% bonded values 
bond_tau_max = 15.72; % Mpa initial 
bond_tau_res = 1.53; % Mpa residual 
bond_slip_max = 0.2; % mm max slip
bond_slip_ult = 0.7; % mm residual slip
bond_fatigue_k = 0.1965;            % decrease value 0.1985
act_ratio = 0.75;
if strcmp(kind,'rod')
    % rod values
    frp_E = 136000; % Mpa
    frp_area = pi*9^2/4; % mm^2
    frp_perim = pi*9; %mm total length
    bond_tau_max = 11.35; % Mpa initial 
    bond_tau_res = 1; % Mpa residual
    bond_slip_max = 0.5;% mm max slip
    bond_slip_ult = 1.4;% mm residual slip
    act_ratio = 0.70;
end
% striup values
steel_E = 200000; % Mpa
stir_area = 2*pi*6^2/4; 
steel_fy = 542;% Mpa
stir_spacing = 300; % mm
stir_first_x = 150; % mm location
stir_x = []; 
steel_trans_len = 220; % mm

% concrete values
con_V_peak = 60000; % N，经验闭合参数，不是60000 kN
con_rise_q = 0.025; % mm，剪切位移增长尺度（待标定） 
con_soft_w = 0.60; % mm，裂缝张开软化尺度（待标定）
con_res_ratio = 0.20; % 无量纲，残余抗剪比例（待标定）


steel_sn_n = Inf; 
steel_sn_stress = 200;
steel_sn_exp = 5;
con_sn_n = Inf; 
con_sn_stress = 1; 
con_sn_exp = 8;
strut_limit = Inf;
moment_limit = Inf; % independ values
Q_max = 180000; 
Q_min = 30000;     
N_max = 10000; 
cycle_step = 20;
n_cells = 24;                     % mesh members
opening_limit = 5;
scan_points = 61;
force_tol = 0.05;
slip_tol = 1e-8;
local_tol = 1e-8; 
local_max_iter = 350;
opening_step_max = 0.08;
cyclic_slip_tol = 1e-10;       % Qmax=Qmin
save_cycles = [0 1 10 100 1000 10000];
plot_on = true; 
export_on = true;
verbose = true; 
calc_capacity = true;
output_dir = fullfile(fileparts(mfilename('fullpath')), ['results_NSM_shear_' kind]);
calib_status = 'not_calibrated_for_NSM_shear_fatigue';
