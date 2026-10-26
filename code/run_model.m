function out = run_model(kind, overrides)
% RUN_MODEL 一个算例的统一入口：参数 -> 几何 -> 疲劳 -> 导出/绘图。
% out=run_model(); out=run_model('rod',struct('N_max',100));
if nargin<1, kind='strip'; end
if nargin<2, overrides=struct(); end
cfg=setup_model(kind,overrides);
out=fatigue_run(cfg);
if cfg.export_on||cfg.plot_on, save_results(out); end
end
