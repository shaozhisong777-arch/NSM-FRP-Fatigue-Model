function cfg = setup_model(kind, overrides)
% 加载参数、应用覆盖值、校验并计算裂缝交点；不污染其他函数工作区。
if nargin<1, kind='strip'; end
if nargin<2, overrides=struct(); end
if ~isstruct(overrides)||~isscalar(overrides)
 error('shear:input','overrides must be a scalar struct.'); end
parameters; % 同目录脚本：定义con_width等局部变量，绝不使用global/assignin
parameterNames=setdiff(who,{'overrides','cfg'});
cfg=struct();
for index=1:numel(parameterNames)
 cfg.(parameterNames{index})=eval(parameterNames{index}); % 仅收集本地已定义参数名
end
if isfield(overrides,'kind'), error('shear:input','Pass strip/rod as the first argument, not overrides.kind.'); end
names=fieldnames(overrides);
for index=1:numel(names)
 if ~isfield(cfg,names{index}), error('shear:input','Unknown parameter: %s',names{index}); end
 cfg.(names{index})=overrides.(names{index});
end
% 参数校验和几何模块：求斜裂缝与NSM/箍筋的真实交点及两侧锚固长度。
pos = {'con_width','con_depth','con_flange_width','con_flange_depth','con_fc','con_E','steel_depth','span','shear_span', ...
 'crack_height','crack_exp','frp_E','frp_area','frp_perim','frp_fu','nsm_spacing', ...
 'steel_E','stir_spacing','steel_trans_len','steel_fy','bond_tau_max','bond_slip_max','bond_slip_ult', ...
 'con_V_peak','con_rise_q','con_soft_w','Q_max','opening_limit','force_tol', ...
 'slip_tol','local_tol','opening_step_max','steel_sn_stress', ...
 'steel_sn_exp','con_sn_stress','con_sn_exp'};
for k=1:numel(pos)
 v=cfg.(pos{k});
 if ~isnumeric(v)||~isreal(v)||~isscalar(v)||~isfinite(v)||v<=0
  error('cc19:input','%s must be finite and positive.',pos{k});
 end
end
nonneg={'crack_x','slide_ratio','bond_tau_res','bond_fatigue_k','stir_area', ...
 'Q_min','con_res_ratio','nsm_first_x','stir_first_x','cyclic_slip_tol'};
for k=1:numel(nonneg)
 v=cfg.(nonneg{k});
 if ~isnumeric(v)||~isreal(v)||~isscalar(v)||~isfinite(v)||v<0
  error('cc19:input','%s must be finite and nonnegative.',nonneg{k});
 end
end
ints={'N_max','cycle_step','n_cells','scan_points','local_max_iter','nsm_faces'};
for k=1:numel(ints)
 v=cfg.(ints{k});
 if ~isnumeric(v)||~isreal(v)||~isscalar(v)||~isfinite(v)||v<1||v~=fix(v)
  error('cc19:input','%s must be a positive integer.',ints{k});
 end
end
lim={'cover_cap','steel_sn_n','con_sn_n', ...
 'strut_limit','moment_limit'};
for k=1:numel(lim)
 v=cfg.(lim{k});
 if ~isnumeric(v)||~isreal(v)||~isscalar(v)||isnan(v)||v<=0
  error('cc19:input','%s must be positive or Inf.',lim{k});
 end
end
flags={'nsm_on','plot_on','export_on','verbose','calc_capacity'};
for k=1:numel(flags)
 v=cfg.(flags{k}); if ~isscalar(v)||~(isnumeric(v)||islogical(v))||~any(v==[0 1])
  error('cc19:input','%s must be logical.',flags{k}); end
end
if cfg.n_cells<4||cfg.scan_points<15||cfg.Q_min>cfg.Q_max||cfg.shear_span>cfg.span/2 ...
 ||cfg.steel_depth>=cfg.con_depth||cfg.crack_height>cfg.con_depth||cfg.con_flange_depth>=cfg.con_depth ...
 ||cfg.bond_slip_ult<=cfg.bond_slip_max||cfg.bond_tau_res>cfg.bond_tau_max||cfg.con_res_ratio>1 ...
 ||~isnumeric(cfg.crack_angle)||~isreal(cfg.crack_angle)||~isscalar(cfg.crack_angle)||~isfinite(cfg.crack_angle)||cfg.crack_angle<=0||cfg.crack_angle>=90 ...
 ||~isnumeric(cfg.frp_angle)||~isreal(cfg.frp_angle)||~isscalar(cfg.frp_angle)||~isfinite(cfg.frp_angle)||cfg.frp_angle<=0||cfg.frp_angle>90
 error('cc19:input','Inconsistent geometry, angles, load range or bond parameters.');
end
if ~isnumeric(cfg.act_ratio)||~isreal(cfg.act_ratio)||~isscalar(cfg.act_ratio) ...
 ||~isfinite(cfg.act_ratio)||cfg.act_ratio<=0||cfg.act_ratio>1
 error('shear:input','act_ratio must be a scalar in (0,1].'); end
if ~isnumeric(cfg.nsm_y_bot)||~isscalar(cfg.nsm_y_bot)||~isfinite(cfg.nsm_y_bot) ...
 ||~isnumeric(cfg.nsm_y_top)||~isscalar(cfg.nsm_y_top)||~isfinite(cfg.nsm_y_top)
 error('shear:input','NSM heights must be finite scalars.'); end
if cfg.nsm_y_bot<0||cfg.nsm_y_top>cfg.con_depth||cfg.nsm_y_top<=cfg.nsm_y_bot
 error('cc19:input','Require 0 <= nsmYBottom < nsmYTop <= depth.'); end
cfg.theta=cfg.crack_angle*pi/180; cfg.alpha=cfg.frp_angle*pi/180;
cfg.kinematicDenominator=cos(cfg.theta)+cfg.slide_ratio*sin(cfg.theta);
cfg.nsmProjection=(sin(cfg.theta+cfg.alpha)-cfg.slide_ratio*cos(cfg.theta+cfg.alpha))/cfg.kinematicDenominator;
if cfg.nsmProjection<=0, error('cc19:input','The assumed crack motion does not tension the NSM bars.'); end
cfg.crackTopX=cfg.crack_x+cfg.crack_height/tan(cfg.theta);
if cfg.crackTopX>cfg.shear_span+1e-8
 error('cc19:input','The critical crack leaves the modelled shear span.'); end
if isempty(cfg.nsm_segments)
 xb=cfg.nsm_first_x:cfg.nsm_spacing:cfg.shear_span;
 dy=cfg.nsm_y_top-cfg.nsm_y_bot;
 segments=[xb(:),cfg.nsm_y_bot*ones(numel(xb),1), ...
  xb(:)-dy/tan(cfg.alpha),cfg.nsm_y_top*ones(numel(xb),1)];
else
 segments=cfg.nsm_segments;
 if ~isnumeric(segments)||~isreal(segments)||size(segments,2)~=4||any(~isfinite(segments(:)))
  error('cc19:input','nsmSegments must be a finite n-by-4 matrix.'); end
end
% bars columns: xCross,yCross,L_lower,L_upper,shape,actualAlphaRadians
bars=zeros(0,6); crack0=[cfg.crack_x;0]; crackD=[cfg.crackTopX-cfg.crack_x;cfg.crack_height];
if cfg.nsm_on
 for i=1:size(segments,1)
  a=segments(i,1:2)'; b=segments(i,3:4)'; d=b-a;
  if norm(d)<=0||d(2)<=0||d(1)>1e-8
   error('cc19:input','Each NSM segment must run from the bottom/right to the top/left.'); end
  if any(a<[0;0])||any(a>[cfg.shear_span;cfg.con_depth])||b(2)<0||b(2)>cfg.con_depth
   error('cc19:input','NSM segment endpoints must be within beam boundaries.'); end
  % Clip an automatically generated bar at x=0; custom bars must lie in the span.
  if b(1)<0 && isempty(cfg.nsm_segments)
   b=a+(0-a(1))/d(1)*d; d=b-a;
  elseif b(1)<0||b(1)>cfg.shear_span
   error('cc19:input','Custom NSM segment leaves the shear span.');
  end
  A=[d,-crackD]; if abs(det(A))<1e-10, continue; end
  t=A\(crack0-a);
  if t(1)>1e-8&&t(1)<1-1e-8&&t(2)>0&&t(2)<1
   xy=a+t(1)*d; al=atan2(d(2),-d(1));
   proj=(sin(cfg.theta+al)-cfg.slide_ratio*cos(cfg.theta+al))/cfg.kinematicDenominator;
   if proj<=0, error('cc19:input','A custom bar is not opened in tension.'); end
   bars(end+1,:)=[xy',t(1)*norm(d),(1-t(1))*norm(d), ...
    (1-xy(2)/cfg.crack_height)^cfg.crack_exp,al];
  end
 end
end
cfg.bars=bars; cfg.nBars=size(bars,1); cfg.generatedSegments=segments;
if isempty(cfg.stir_x), sx=cfg.stir_first_x:cfg.stir_spacing:cfg.shear_span; else, sx=cfg.stir_x; end
if ~isnumeric(sx)||~isreal(sx)||any(~isfinite(sx(:)))||any(sx(:)<0)||any(sx(:)>cfg.shear_span)
 error('cc19:input','Invalid stirrup coordinates.'); end
sy=(sx(:)-cfg.crack_x)*tan(cfg.theta); use=sy>0 & sy<cfg.crack_height;
if cfg.stir_area==0, use(:)=false; end
% sx may be row or column; normalize without relying on implicit expansion.
cfg.steel=[reshape(sx(use),[],1),sy(use),(1-sy(use)/cfg.crack_height).^cfg.crack_exp];
cfg.nSteel=size(cfg.steel,1);
if ~isnumeric(cfg.save_cycles)||~isreal(cfg.save_cycles)||any(~isfinite(cfg.save_cycles(:))) ...
 ||any(cfg.save_cycles(:)<0)||any(cfg.save_cycles(:)~=fix(cfg.save_cycles(:)))
 error('cc19:input','snapshotCycles must be nonnegative integers.'); end
cfg.save_cycles=unique([0 1 reshape(cfg.save_cycles,1,[]) cfg.N_max]);
cfg.save_cycles=cfg.save_cycles(cfg.save_cycles<=cfg.N_max);
if ~(ischar(cfg.output_dir)||(isstring(cfg.output_dir)&&isscalar(cfg.output_dir)))||isempty(char(cfg.output_dir))
 error('cc19:input','outputDir must be a path.'); end
cfg.output_dir=char(cfg.output_dir);
cfg.codeVersion='shear-refactor-1.0';
cfg.sourceNotes=struct('equilibrium','Chen et al. 2022 Eqs.9a-9d; inclined FRP uses vertical projection', ...
 'ECC','Chen et al. 2024 Eqs.1-5: mechanism reference only; no ECC layer in this NSM model', ...
 'closure','Vc(q,w), crack shape and steel transfer length are inherited assumptions requiring calibration', ...
 'fatigue','0.1965 and activation threshold inherited from supplied flexural reference; not validated shear-fatigue data');
cfg.forceDefinition='Q is total actuator load; V=Q/2; T is one physical NSM bar axial force.';
end
