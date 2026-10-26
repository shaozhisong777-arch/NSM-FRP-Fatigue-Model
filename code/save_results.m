function save_results(out)
% 集中导出MAT、CSV和状态说明；保留每根筋及两锚固侧的可核查输出。
figs=[];
if out.parameters.plot_on && ~isempty(out.history), figs=plot_history(out); end
if ~out.parameters.export_on, return; end
cfg=out.parameters; dest=cfg.output_dir; if ~exist(dest,'dir'), mkdir(dest); end
save(fullfile(dest,'results_NSM_shear.mat'),'out','-v7');
write_csv(fullfile(dest,'history.csv'),out.historyColumns,out.history);
write_csv(fullfile(dest,'initial_capacity.csv'),out.initialCapacity.columns,out.initialCapacity.curve);
write_csv(fullfile(dest,'NSM_crossings.csv'),{'x_mm','y_mm','Llower_mm','Lupper_mm','shape','alpha_rad'},cfg.bars);
for i=1:numel(out.snapshots)
 z=out.snapshots(i);
 write_csv(fullfile(dest,sprintf('NSM_fields_N%d.csv',z.N)),z.field.columns,z.field.NSMfields);
 write_csv(fullfile(dest,sprintf('stirrups_N%d.csv',z.N)), ...
  {'x_mm','y_mm','shape','strain','stress_MPa','MinerDamage'},z.field.steel);
 k=z.field.crack;
 write_csv(fullfile(dest,sprintf('crack_N%d.csv',z.N)), ...
  {'y_mm','normalOpening_mm','tangentialSliding_mm','verticalJump_mm','horizontalJump_mm'}, ...
  [k.y,k.opening,k.sliding,k.verticalJump,k.horizontalJump]);
end
for i=1:numel(figs), print(figs(i),fullfile(dest,sprintf('figure_%d.png',i)),'-dpng','-r150'); end
f=fopen(fullfile(dest,'status_and_sources.txt'),'w');
if f<0, error('cc19:export','Cannot write status.'); end
guard=onCleanup(@() fclose(f));
fprintf(f,'model=NSM-strengthened critical-crack shear fatigue\nversion=%s\nstatus=%s\n',cfg.codeVersion,out.status);
fprintf(f,'lastBalancedCycle=%g\nfailureCycle=%g\nfailureBracket=[%g,%g]\n', ...
 out.lastCycle,out.failureCycle,out.failureBracket);
fprintf(f,'calibration=%s\n%s\n',cfg.calib_status,cfg.forceDefinition);
fprintf(f,'Qmax_N=%g\nQmin_N=%g\ncrossedNSMlinesPerFace=%d\nfaces=%d\n',cfg.Q_max,cfg.Q_min,cfg.nBars,cfg.nsm_faces);
fprintf(f,'steelFatigueEnabled=%d\nconcreteFatigueEnabled=%d\n',isfinite(cfg.steel_sn_n),isfinite(cfg.con_sn_n));
fprintf(f,'Default fatigue mechanism: local NSM bond degradation. S-N mechanisms require supplied calibration.\n');
fprintf(f,'No midspan deflection or experimental fatigue life is inferred from the crack-jump coordinate.\n');
names=fieldnames(cfg.sourceNotes);
for i=1:numel(names), fprintf(f,'%s: %s\n',names{i},cfg.sourceNotes.(names{i})); end
end

function write_csv(file,headers,data)
f=fopen(file,'w'); if f<0, error('cc19:export','Cannot open %s.',file); end
guard=onCleanup(@() fclose(f));
fprintf(f,'%s',headers{1}); for j=2:numel(headers), fprintf(f,',%s',headers{j}); end
fprintf(f,'\n');
if ~isempty(data)
 fmt=[repmat('%.12g,',1,size(data,2)-1),'%.12g\n']; fprintf(f,fmt,data');
end
end

function figs=plot_history(out)
% 裂缝位移和剪力分担；不把裂缝位移标为跨中挠度。
h=out.history;
figs(1)=figure('Name','剪力分担');
plot(h(:,1),h(:,7:9)/1000,'LineWidth',1.5); grid on;
xlabel('Cycles N'); ylabel('Shear contribution (kN)'); legend('Concrete','Stirrups','NSM');
figs(2)=figure('Name','裂缝变形');
plot(h(:,1),h(:,[2 4 5]),'LineWidth',1.5); grid on;
xlabel('Cycles N'); ylabel('Crack displacement (mm)'); legend('Vertical q','Opening w','Sliding v');
end
