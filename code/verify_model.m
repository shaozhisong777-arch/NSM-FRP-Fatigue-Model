function report = verify_model()
% 数值和机制验证，不等于抗剪疲劳试验校准。可在MATLAB或GNU Octave运行。
cfg=setup_model('strip');
assert(cfg.nBars>0 && cfg.nSteel>0);
% 双侧有限锚固的独立线弹性解析解，包含短侧主导和两端零轴力边界。
pa=cfg; pa.n_cells=100; z=zeros(pa.n_cells+1,1); tm=pa.bond_tau_max*ones(size(z));
d=0.02; L1=120; L2=260;
a=solve_anchor(pa,d,L1,L2,z,z,tm,tm,false);
lambda=sqrt(pa.frp_perim*pa.bond_tau_max/(pa.bond_slip_max*pa.frp_E*pa.frp_area));
K1=pa.frp_E*pa.frp_area*lambda*tanh(lambda*L1); K2=pa.frp_E*pa.frp_area*lambda*tanh(lambda*L2);
exact=d/(1/K1+1/K2); relative=abs(a.force/exact-1);
assert(a.ok && relative<0.002);
assert(a.forceResidual<0.01);
assert(abs(a.sides{1}.slip(1)+a.sides{2}.slip(1)-d)<1e-10);
assert(max([a.sides{1}.force(end),a.sides{2}.force(end)])<1e-5);
b=solve_anchor(pa,d,40,L2,z,z,tm,tm,false);
assert(b.force<a.force && b.sides{1}.slip(1)>b.sides{2}.slip(1));
weakened=solve_anchor(pa,d,L1,L2,z,z,0.5*tm,tm,false);
assert(weakened.force<a.force);
% 按老师原始公式保留tauR下限，未激活/首循环保持初值。
ns=[0 1 10 1e12]; t=bond_strength(cfg,ns);
assert(t(1)==cfg.bond_tau_max && t(2)==cfg.bond_tau_max && all(t>=cfg.bond_tau_res));
assert(abs(t(3)-max(cfg.bond_tau_res,cfg.bond_tau_max*(1-0.1965)))<1e-12);
% 与未加固对照在同一可承受荷载下比较，NSM的力确实参与全梁平衡。
o=struct('Q_max',110000,'Q_min',20000,'N_max',1,'plot_on',false, ...
 'export_on',false,'verbose',false,'calc_capacity',false,'n_cells',16,'scan_points',41);
strengthened=run_model('strip',o); o.nsm_on=false; control=run_model('strip',o);
assert(~isempty(strengthened.lastState)&&~isempty(control.lastState));
assert(strengthened.lastState.Vnsm>0 && control.lastState.Vnsm==0);
assert(strengthened.lastState.q<control.lastState.q);
assert(max(strengthened.lastState.steelStress)<max(control.lastState.steelStress));
globalError=max(strengthened.history(:,10));
assert(globalError<cfg.force_tol*1.01);
% 相同最大最小荷载没有循环，不得仅因N增加而产生疲劳退化。
steady=o; steady.nsm_on=true; steady.Q_min=steady.Q_max; steady.N_max=50;
steady.act_ratio=0.001; noCycle=run_model('strip',steady);
for j=1:noCycle.parameters.nBars
 for s=1:2, assert(all(noCycle.memory.age{j,s}==0)); end
end
% 人为降低触发阈值的机制测试：保证确有界面退化和剪力重分配。
fat=o; fat.nsm_on=true; fat.Q_max=165000; fat.N_max=40;
fat.act_ratio=0.10; fatigue=run_model('strip',fat);
assert(~isempty(fatigue.lastState));
activeCount=0; untouchedCount=0;
for j=1:fatigue.parameters.nBars
 for s=1:2
  activeCount=activeCount+sum(fatigue.memory.age{j,s}>1);
  untouchedCount=untouchedCount+sum(fatigue.memory.age{j,s}==0);
 end
end
assert(activeCount>0 && untouchedCount>0);
assert(fatigue.lastState.q>fatigue.history(1,2));
assert(all(diff(fatigue.history(:,2))>=-1e-7));
assert(max(fatigue.history(:,10))<cfg.force_tol*1.01);
% 入口和分模块必须一致，且错误不能伪装成物理失效。
pp=setup_model('strip',fat);
modular=fatigue_run(pp);
assert(isequal(size(fatigue.history),size(modular.history)));
assert(max(abs(fatigue.history(:)-modular.history(:)))<1e-9);
% 单根完全脱黏并不等于整梁破坏；其余NSM和RC仍须重新平衡。
loss=section_response(strengthened.parameters,2.5,strengthened.memory,false);
assert(sum(loss.memory.failedFRP)==1 && loss.localOK);
[remaining,remainingInfo]=solve_equilibrium(strengthened.parameters,loss.memory,55000,0,false);
assert(remainingInfo.ok && remaining.Vnsm>0 && sum(remaining.memory.failedFRP)==1);
assert(remaining.forceResidual<cfg.force_tol);
% 可选Miner接口用人为极低寿命参数验证，绝不作为材料标定数据。
sn=o; sn.nsm_on=true; sn.N_max=2;
sn.steel_sn_n=1; sn.steel_sn_stress=10; sn.steel_sn_exp=3;
steelSN=run_model('strip',sn); assert(all(steelSN.memory.steelDamage==1));
sn=o; sn.nsm_on=true; sn.N_max=2;
sn.con_sn_n=1; sn.con_sn_stress=0.01; sn.con_sn_exp=3;
concreteSN=run_model('strip',sn); assert(concreteSN.memory.concreteDamage==1);
rejected=false;
try, setup_model('strip',struct('crack_angle',0)); catch, rejected=true; end
assert(rejected);
report=struct('elasticAnchorRelativeError',relative,'anchorForceMismatch_N',a.forceResidual, ...
 'maxGlobalEquilibriumResidual_N',max([globalError;fatigue.history(:,10)]), ...
 'strengthenedCrackJump_mm',strengthened.lastState.q, ...
 'controlCrackJump_mm',control.lastState.q,'fatigueActiveNodes',activeCount, ...
 'fatigueUnactivatedNodes',untouchedCount,'zeroLoadRangeNoFatigue',true, ...
 'modularEntryMatch',true,'singleBarLossBeamContinues',true, ...
 'optionalMinerInterfacesChecked',true,'experimentalCalibration',false);
% 网格收敛：同一独立解析解，随加密误差应下降。
meshError=zeros(1,3); meshSizes=[25 50 100];
for i=1:3
 test=cfg; test.n_cells=meshSizes(i); zz=zeros(test.n_cells+1,1);
 aa=solve_anchor(test,d,L1,L2,zz,zz,test.bond_tau_max+zz,test.bond_tau_max+zz,false);
 meshError(i)=abs(aa.force/exact-1);
end
assert(all(diff(meshError)<0));
% 循环块近似的步长敏感性，不将一次块更新等同逐循环精确积分。
step=fat; step.N_max=20; step.cycle_step=1; one=run_model('strip',step);
step.cycle_step=5; five=run_model('strip',step);
stepError=abs(one.lastState.q-five.lastState.q)/one.lastState.q;
assert(stepError<0.01);
% 杆材与文件导出：测试输出只写入独立临时目录。
dest=tempname; cleanup=onCleanup(@() remove_test_output(dest));
exportOpt=o; exportOpt.export_on=true; exportOpt.output_dir=dest;
rod=run_model('rod',exportOpt); assert(~isempty(rod.history));
loaded=load(fullfile(dest,'results_NSM_shear.mat'));
assert(isequal(loaded.out.history,rod.history));
assert(exist(fullfile(dest,'history.csv'),'file')==2);
exportOpt.Q_max=1e9; overloaded=run_model('strip',exportOpt);
assert(isempty(overloaded.history));
assert(strcmp(overloaded.status,'initial_no_equilibrium_in_model_domain'));
loaded=load(fullfile(dest,'results_NSM_shear.mat'));
assert(isempty(loaded.out.history));
report.meshSizes=meshSizes; report.elasticMeshErrors=meshError;
report.cycleStepRelativeDifference=stepError;
report.rodAndExportChecked=true; report.overloadExportChecked=true;
disp(report); fprintf('NSM shear equilibrium verification passed in this runtime.\n');
end

function remove_test_output(dest)
if exist(dest,'dir'), rmdir(dest,'s'); end
end
