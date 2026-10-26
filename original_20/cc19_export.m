function cc19_export(out,figs)
% 集中导出MAT、CSV和状态说明；保留每根筋及两锚固侧的可核查输出。
if nargin<2, figs=[]; end
p=out.parameters; dest=p.outputDir; if ~exist(dest,'dir'), mkdir(dest); end
save(fullfile(dest,'results_NSM_shear.mat'),'out','-v7');
cc19_csv(fullfile(dest,'history.csv'),out.historyColumns,out.history);
cc19_csv(fullfile(dest,'initial_capacity.csv'),out.initialCapacity.columns,out.initialCapacity.curve);
cc19_csv(fullfile(dest,'NSM_crossings.csv'),{'x_mm','y_mm','Llower_mm','Lupper_mm','shape','alpha_rad'},p.bars);
for i=1:numel(out.snapshots)
 z=out.snapshots(i);
 cc19_csv(fullfile(dest,sprintf('NSM_fields_N%d.csv',z.N)),z.field.columns,z.field.NSMfields);
 cc19_csv(fullfile(dest,sprintf('stirrups_N%d.csv',z.N)), ...
  {'x_mm','y_mm','shape','strain','stress_MPa','MinerDamage'},z.field.steel);
 k=z.field.crack;
 cc19_csv(fullfile(dest,sprintf('crack_N%d.csv',z.N)), ...
  {'y_mm','normalOpening_mm','tangentialSliding_mm','verticalJump_mm','horizontalJump_mm'}, ...
  [k.y,k.opening,k.sliding,k.verticalJump,k.horizontalJump]);
end
for i=1:numel(figs), print(figs(i),fullfile(dest,sprintf('figure_%d.png',i)),'-dpng','-r150'); end
f=fopen(fullfile(dest,'status_and_sources.txt'),'w');
if f<0, error('cc19:export','Cannot write status.'); end
guard=onCleanup(@() fclose(f));
fprintf(f,'model=NSM-strengthened critical-crack shear fatigue\nversion=%s\nstatus=%s\n',p.codeVersion,out.status);
fprintf(f,'lastBalancedCycle=%g\nfailureCycle=%g\nfailureBracket=[%g,%g]\n', ...
 out.lastCycle,out.failureCycle,out.failureBracket);
fprintf(f,'calibration=%s\n%s\n',p.calibrationStatus,p.forceDefinition);
fprintf(f,'Qmax_N=%g\nQmin_N=%g\ncrossedNSMlinesPerFace=%d\nfaces=%d\n',p.Qmax,p.Qmin,p.nBars,p.nsmFaces);
fprintf(f,'steelFatigueEnabled=%d\nconcreteFatigueEnabled=%d\n',isfinite(p.steelSNrefCycles),isfinite(p.concreteSNrefCycles));
fprintf(f,'Default fatigue mechanism: local NSM bond degradation. S-N mechanisms require supplied calibration.\n');
fprintf(f,'No midspan deflection or experimental fatigue life is inferred from the crack-jump coordinate.\n');
names=fieldnames(p.sourceNotes);
for i=1:numel(names), fprintf(f,'%s: %s\n',names{i},p.sourceNotes.(names{i})); end
end

function cc19_csv(file,headers,data)
f=fopen(file,'w'); if f<0, error('cc19:export','Cannot open %s.',file); end
guard=onCleanup(@() fclose(f));
fprintf(f,'%s',headers{1}); for j=2:numel(headers), fprintf(f,',%s',headers{j}); end
fprintf(f,'\n');
if ~isempty(data)
 fmt=[repmat('%.12g,',1,size(data,2)-1),'%.12g\n']; fprintf(f,fmt,data');
end
end
