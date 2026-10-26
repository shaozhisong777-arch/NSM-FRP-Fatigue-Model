function out = ff19(kind,overrides)
% 统一入口。保留ff19名；只调用外部17个模块，删除内嵌副本以避免不同步。
% 示例 out=ff19('strip',struct('Nmax',100,'makePlots',false));
if nargin<1, kind='strip'; end
if nargin<2, overrides=struct(); end
if ~isstruct(overrides)||~isscalar(overrides), error('cc19:input','Overrides must be a scalar struct.'); end
p=cc19_parameters(kind); names=fieldnames(overrides);
for i=1:numel(names)
 if ~isfield(p,names{i}), error('cc19:input','Unknown option: %s',names{i}); end
 p.(names{i})=overrides.(names{i});
end
out=cc19_run(p); figs=[];
if p.makePlots, figs=cc19_plot(out); end
if p.exportResults, cc19_export(out,figs); end
end
