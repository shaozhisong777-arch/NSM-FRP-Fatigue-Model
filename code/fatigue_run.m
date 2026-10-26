function out = fatigue_run(cfg)
% 疲劳主循环：冻结损伤求最大/最小荷载平衡 -> 更新局部计数和可选Miner损伤。
% 全局V随NSM黏结退化而重分配；单根筋损失后继续寻找整梁平衡。
memory=new_memory(cfg);
out=struct('parameters',cfg,'status','running','lastCycle',0,'failureCycle',NaN, ...
 'failureBracket',[NaN NaN],'history',zeros(0,16),'snapshots',struct([]), ...
 'lastState',[],'lastLowState',[],'memory',memory, ...
 'calib_status',cfg.calib_status,'initialCapacity',[], ...
 'lastInfo',[],'failureCapacity',NaN);
out.historyColumns={'N','qMax_mm','qMin_mm','wMax_mm','slidingMax_mm', ...
 'Vmax_N','Vc_N','Vs_N','Vnsm_N','beamResidual_N','anchorResidual_N', ...
 'failedNSMlines','maxSteelStress_MPa','maxSteelMinerDamage','concreteMinerDamage','cycleBlock'};
if cfg.calc_capacity, out.initialCapacity=capacity_scan(cfg,memory);
else, out.initialCapacity=struct('curve',zeros(0,5), ...
 'columns',{{'q_mm','V_N','Vc_N','Vs_N','Vnsm_N'}},'status','not_requested'); end
[peak,info]=solve_equilibrium(cfg,memory,cfg.Q_max/2,0,false); out.lastInfo=info;
if ~info.ok
 out.status=['initial_' info.status]; out.failureCapacity=info.capacity;
 if strcmp(info.status,'no_equilibrium_in_model_domain')
  out.failureCycle=0; out.failureBracket=[0 0];
 end
 if cfg.verbose, fprintf('%s: %s\n',cfg.kind,out.status); end
 return;
end
memory=peak.memory;
[low,li]=solve_equilibrium(cfg,memory,cfg.Q_min/2,peak.q,true);
if ~li.ok, out.status=['minimum_load_' li.status]; out.lastInfo=li; return; end
N=0; out.history=history_row(N,peak,low,memory,0);
out.snapshots=snapshot(cfg,N,peak,low,memory);
while N<cfg.N_max
 [mask,~]=active_nodes(cfg,peak,low,memory);
 if ~any(cellfun(@(x) any(x(:)),mask(:))) ...
   &&~isfinite(cfg.steel_sn_n)&&~isfinite(cfg.con_sn_n)
  for n=cfg.save_cycles(cfg.save_cycles>N)
   out.history(end+1,:)=history_row(n,peak,low,memory,n-N);
   out.snapshots(end+1)=snapshot(cfg,n,peak,low,memory); N=n;
  end
  out.status='runout_no_active_degradation'; break;
 end
 target=cfg.save_cycles(find(cfg.save_cycles>N,1));
 dn=min([cfg.cycle_step,cfg.N_max-N,target-N]);
 while true
  proposed=advance_damage(cfg,memory,peak,low,mask,dn);
  [next,ni]=solve_equilibrium(cfg,proposed,cfg.Q_max/2,peak.q,false);
  rapid=ni.ok && next.q-peak.q>cfg.opening_step_max;
  if dn>1 && (~ni.ok||rapid), dn=max(1,floor(dn/2)); continue; end
  break;
 end
 out.lastInfo=ni;
 if ~ni.ok
  out.status=ni.status; out.failureCapacity=ni.capacity;
  if strcmp(ni.status,'no_equilibrium_in_model_domain')||strcmp(ni.status,'user_concrete_strut_limit')||strcmp(ni.status,'user_flexural_limit')
   out.failureCycle=N+dn; out.failureBracket=[N N+dn];
  end
  break;
 end
 nextMemory=next.memory;
 [nextLow,niLow]=solve_equilibrium(cfg,nextMemory,cfg.Q_min/2,next.q,true);
 if ~niLow.ok, out.status=['minimum_load_' niLow.status]; out.lastInfo=niLow; break; end
 N=N+dn; peak=next; low=nextLow; memory=nextMemory;
 out.history(end+1,:)=history_row(N,peak,low,memory,dn);
 if any(cfg.save_cycles==N), out.snapshots(end+1)=snapshot(cfg,N,peak,low,memory); end
end
if strcmp(out.status,'running'), out.status='runout_at_Nmax'; end
out.lastCycle=N; out.lastState=peak; out.lastLowState=low; out.memory=memory;
if out.snapshots(end).N~=N, out.snapshots(end+1)=snapshot(cfg,N,peak,low,memory); end
if cfg.verbose
 fprintf('%s NSM shear: %s; last balanced cycle=%g\n',cfg.kind,out.status,N);
 fprintf('V=%.6g N = Vc %.6g + Vs %.6g + Vnsm %.6g; q=%.6g mm\n',peak.V,peak.Vc,peak.Vs,peak.Vnsm,peak.q);
 fprintf('Crossed NSM lines per face=%d, faces=%d; calibration=%s\n',cfg.nBars,cfg.nsm_faces,cfg.calib_status);
 if isfinite(out.failureCycle), fprintf('Model failure bracket: [%g,%g]\n',out.failureBracket); end
end
end

function m=new_memory(cfg)
m=struct('bondMax',{cell(cfg.nBars,2)},'age',{cell(cfg.nBars,2)}, ...
 'activated',{cell(cfg.nBars,2)},'failedFRP',false(cfg.nBars,1), ...
 'barFailure',{repmat({''},cfg.nBars,1)},'steelDamage',zeros(cfg.nSteel,1),'concreteDamage',0);
for j=1:cfg.nBars
 for s=1:2
  m.bondMax{j,s}=zeros(cfg.n_cells+1,1); m.age{j,s}=zeros(cfg.n_cells+1,1);
  m.activated{j,s}=false(cfg.n_cells+1,1);
 end
end
end

function row=history_row(N,peak,low,m,dn)
row=[N,peak.q,low.q,peak.w,peak.v,peak.V,peak.Vc,peak.Vs,peak.Vnsm, ...
 peak.forceResidual,peak.localForceResidual,sum(m.failedFRP),max([0;peak.steelStress]), ...
 max([0;m.steelDamage]),m.concreteDamage,dn];
end

function z=snapshot(cfg,N,peak,low,m)
z=struct('N',N,'peak',peak,'minimum',low,'field',sample_fields(cfg,peak,m), ...
 'memory',m,'reference',truss_reference(cfg,peak));
end

function [active,amplitude] = active_nodes(cfg,peak,low,memory)

active=cell(cfg.nBars,2); 
amplitude=cell(cfg.nBars,2);
for j=1:cfg.nBars % FRP different sides
 for s=1:2% FRP different sides
  active{j,s}=false(cfg.n_cells+1,1); 
  amplitude{j,s}=zeros(cfg.n_cells+1,1);
  if cfg.Q_max==cfg.Q_min||memory.failedFRP(j)||isempty(peak.fields{j})||isempty(low.fields{j}), continue; 
  end
  a=peak.fields{j}.sides{s}; b=low.fields{j}.sides{s};
  amplitude{j,s}=max(0,a.slip-b.slip);
  active{j,s}=(memory.activated{j,s}|a.maxSlip>cfg.act_ratio*cfg.bond_slip_max) ...
   & amplitude{j,s}>cfg.cyclic_slip_tol;
 end
end
end

function v = sample_fields(cfg,st,memory)

if nargin<3, memory=st.memory; end
rows=zeros(0,12);
for j=1:cfg.nBars
 if isempty(st.fields{j}), continue; end
 for s=1:2
  a=st.fields{j}.sides{s}; n=numel(a.x);
  rows=[rows; j*ones(n,1),s*ones(n,1),a.x,a.slip,a.maxSlip,a.tau,a.tauM, ...
   a.force,a.strain,memory.age{j,s},a.zone,memory.failedFRP(j)*ones(n,1)];
 end
end
v=struct('NSMfields',rows,'columns',{{'bar','side','x_mm','slip_mm','maxSlip_mm', ...
 'bondStress_MPa','peakBondStress_MPa','axialForce_N','FRPstrain','localCycles','zone','barFailed'}}, ...
 'steel',[cfg.steel,st.steelStrain,st.steelStress,memory.steelDamage], ...
 'crack',crack_kinematics(cfg,st.q));
end

function c = capacity_scan(cfg,memory)
% 当前损伤下的静力承载曲线数值扫描；仅用于诊断，不以FRP脱黏等同整梁失效。
x=unique([0,linspace(0,0.15,12),linspace(0,cfg.opening_limit,cfg.scan_points)]);
curve=NaN(numel(x),5);
bad=0;
pathMemory=memory;
for i=1:numel(x)
 st=section_response(cfg,x(i),pathMemory,false);
 if st.localOK
  curve(i,:)=[x(i),st.V,st.Vc,st.Vs,st.Vnsm]; 
  pathMemory=st.memory;
 else, bad=bad+1;
       curve(i,1)=x(i); 
 end
end
valid=find(isfinite(curve(:,2)));
if isempty(valid), cap=NaN; q=NaN;
else, [cap,k]=max(curve(valid,2)); 
    q=curve(valid(k),1); 
end
c=struct('curve',curve,'columns',{{'q_mm','V_N','Vc_N','Vs_N','Vnsm_N'}}, ...
 'sampledCapacity',cap,'qAtSampledPeak',q,'numericalFailures',bad, ...
 'status','sampled_model_domain_capacity');
if bad>0, c.status='incomplete_capacity_scan'; end
end

function a = truss_reference(cfg,st)
% 旧文件名保留；现只给出均匀应变桁架公式的对照，不再用抗弯阶段插值控制状态。
% 实际求解始终用离散交点轴力之和，不再乘一遍d/s，避免重复计算NSM数量。
if cfg.nBars==0, v=0; else
 epsMean=mean(st.barForce/(cfg.frp_E*cfg.frp_area));
 v=cfg.nsm_faces*cfg.frp_area*cfg.frp_E*epsMean*cfg.crack_height/cfg.nsm_spacing ...
  *(1/tan(cfg.theta)+1/tan(cfg.alpha))*sin(cfg.alpha);
end
a=struct('uniformStrainTrussReference_N',v,'discreteIntersectionSum_N',st.Vnsm, ...
 'usedByStateSolver',false,'note','Truss reference only; actual bar intersections and two-sided anchorage govern the model.');
end

function proposed=advance_damage(cfg,memory,peak,low,mask,dn)
% 只提出当前循环块的损伤；平衡成功后才在主循环提交。
  proposed=memory;
  for j=1:cfg.nBars
   for s=1:2
    proposed.activated{j,s}=memory.activated{j,s}|mask{j,s};
    proposed.age{j,s}(mask{j,s})=memory.age{j,s}(mask{j,s})+dn;
   end
  end
  % Optional steel S-N: input is actual max-minus-min stress range at each crossing.
  if isfinite(cfg.steel_sn_n) && cfg.Q_max>cfg.Q_min
   range=max(0,peak.steelStress-low.steelStress);
   life=cfg.steel_sn_n*(cfg.steel_sn_stress./max(range,realmin)).^cfg.steel_sn_exp;
   proposed.steelDamage=min(1,memory.steelDamage+dn./life);
  end
  % Optional concrete S-N uses the equivalent section shear-stress range, MPa.
  if isfinite(cfg.con_sn_n) && cfg.Q_max>cfg.Q_min
   qq=linspace(low.q,peak.q,41); ww=qq/cfg.kinematicDenominator;
   vc=cfg.con_V_peak*(1-exp(-qq/cfg.con_rise_q)) ...
    .*(cfg.con_res_ratio+(1-cfg.con_res_ratio)*exp(-ww/cfg.con_soft_w)) ...
    *(1-memory.concreteDamage);
   range=(max(vc)-min(vc))/(cfg.con_width*cfg.steel_depth);
   life=cfg.con_sn_n*(cfg.con_sn_stress/max(range,realmin))^cfg.con_sn_exp;
   proposed.concreteDamage=min(1,memory.concreteDamage+dn/life);
  end
end
