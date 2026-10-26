function st = section_response(cfg,q,memory,unload)
% 给定裂缝位移q，计算Vc、实际相交箍筋Vs及NSM竖向分力。
% Vc经验关系/箍筋传递长度为闭合假设，不冒充两篇论文中的预测本构。
if nargin<4, unload=false; end
if ~isscalar(q)||~isfinite(q)||q<0, error('cc19:trial','q must be nonnegative.'); end
k=crack_kinematics(cfg,q); 
next=memory;
Vc=cfg.con_V_peak*(1-exp(-q/cfg.con_rise_q)) ...
 *(cfg.con_res_ratio+(1-cfg.con_res_ratio)*exp(-k.wMax/cfg.con_soft_w)) ...
 *(1-memory.concreteDamage);
steelEps=q*cfg.steel(:,3)/cfg.steel_trans_len;
steelStress=min(cfg.steel_E*steelEps,cfg.steel_fy); 
steelStress(memory.steelDamage>=1)=0;
Vs=sum(cfg.stir_area*steelStress);
T=zeros(cfg.nBars,1); 
fields=cell(cfg.nBars,1); 
failures=memory.barFailure;
ok=true; maxResidual=0;
for j=1:cfg.nBars
 if memory.failedFRP(j), continue; end
 b=cfg.bars(j,:); al=b(6);
 projection=(sin(cfg.theta+al)-cfg.slide_ratio*cos(cfg.theta+al))/cfg.kinematicDenominator;
 delta=max(0,q*b(5)*projection);
 tm1=bond_strength(cfg,memory.age{j,1}); 
 tm2=bond_strength(cfg,memory.age{j,2});
 a=solve_anchor(cfg,delta,b(3),b(4),memory.bondMax{j,1},memory.bondMax{j,2},tm1,tm2,unload);
 a.compatibilityResidual=abs(a.sides{1}.slip(1)+a.sides{2}.slip(1)-delta);
 fields{j}=a; ok=ok&&a.ok&&(a.forceResidual<=cfg.force_tol); maxResidual=max(maxResidual,a.forceResidual);
 if ~unload
  next.bondMax{j,1}=a.sides{1}.maxSlip; 
  next.bondMax{j,2}=a.sides{2}.maxSlip;
 end
 fail='';
 if strcmp(a.status,'full_debond'), fail='full_anchorage_debond';
 elseif a.force>=cfg.frp_area*cfg.frp_fu, fail='FRP_tensile_limit';
 elseif a.force>=cfg.cover_cap, fail='user_cover_capacity_limit'; 
 end
 if ~isempty(fail)
  next.failedFRP(j)=true; 
  failures{j}=fail;
  fields{j}.force=0;
  for s=1:2
   fields{j}.sides{s}.tau(:)=0; fields{j}.sides{s}.force(:)=0;
   fields{j}.sides{s}.strain(:)=0;
  end
 else, T(j)=a.force; 
 end
end
if cfg.nBars>0, Vn=cfg.nsm_faces*sum(T.*sin(cfg.bars(:,6))); else, Vn=0; end
next.barFailure=failures;
st=struct('q',q,'w',k.wMax,'v',k.vMax,'Vc',Vc,'Vs',Vs,'Vnsm',Vn, ...
 'V',Vc+Vs+Vn,'barForce',T,'steelStress',steelStress,'steelStrain',steelEps, ...
 'fields',{fields},'memory',next,'localOK',ok,'localForceResidual',maxResidual, ...
 'forceResidual',NaN,'unload',unload);
end
