function a = solve_anchor(cfg,delta,L1,L2,hist1,hist2,tm1,tm2,unload)
% dT/dx=-p_f*tau，du/dx=-T/(Ef*Af)。
% T1=T2、s01+s02=delta

if nargin<9, unload=false; end
[x1,w1]=anchor_mesh(cfg,L1); [x2,w2]=anchor_mesh(cfg,L2);
n=cfg.n_cells; m=2*n+1; il=(n+1:-1:1)'; ir=(n+1:2*n+1)';
hist1=hist1(:); hist2=hist2(:); tm1=tm1(:); tm2=tm2(:);
if any([numel(hist1),numel(hist2),numel(tm1),numel(tm2)]~=n+1)
 error('cc19:anchor','Anchor arrays must contain nCells+1 nodes.'); end
EA=cfg.frp_E*cfg.frp_area; he=[flipud(diff(x1));diff(x2)]; ke=EA./he;
Kb=sparse(1:m,1:m,[ke(1);ke(1:end-1)+ke(2:end);ke(end)],m,m) ...
 +sparse(1:m-1,2:m,-ke,m,m)+sparse(2:m,1:m-1,-ke,m,m);
u=delta*linspace(0,1,m)'; ok=false; h1=hist1; h2=hist2;
for it=1:cfg.local_max_iter
 s1=max(0,u(il)); s2=max(0,delta-u(ir));
 if unload, h1=hist1; h2=hist2; else, h1=max(hist1,s1); h2=max(hist2,s2); end
 [~,k1]=bond_law(cfg,h1,tm1); [~,k2]=bond_law(cfg,h2,tm2);
 c1=cfg.frp_perim*w1.*k1; c2=cfg.frp_perim*w2.*k2;
 diagK=accumarray([il;ir],[c1;c2],[m 1]); rhs=accumarray(ir,c2*delta,[m 1]);
 A=Kb+spdiags(diagK,0,m,m);
 if all(c1==0)||all(c2==0)
  a=anchor_output(cfg,x1,x2,s1,s2,h1,h2,tm1,tm2,0,0,it,true,'full_debond'); return;
 end
 un=A\rhs;
 err=max(abs(un-u));
 if err<=cfg.local_tol*max(1,delta)
  u=un; ok=true; break;
 end
 if it<3, u=un; else, u=0.6*un+0.4*u; end
end


if ~ok
 [u,ok,extra]=anchor_newton(cfg,u,delta,Kb,il,ir,w1,w2,hist1,hist2,tm1,tm2,unload);
 it=it+extra;
end
s1=max(0,u(il)); s2=max(0,delta-u(ir));
if unload, h1=hist1; h2=hist2; else, h1=max(hist1,s1); h2=max(hist2,s2); end
[~,k1]=bond_law(cfg,h1,tm1); [~,k2]=bond_law(cfg,h2,tm2);
t1=k1.*s1; t2=k2.*s2;
F1=cfg.frp_perim*sum(w1.*t1); F2=cfg.frp_perim*sum(w2.*t2);
status='balanced';
if ~ok, status='local_iteration_not_converged'; end
if ~unload && (h1(end)>=cfg.bond_slip_ult||h2(end)>=cfg.bond_slip_ult)
 status='full_debond'; F1=0; F2=0;
end
a=anchor_output(cfg,x1,x2,s1,s2,h1,h2,tm1,tm2,F1,F2,it,ok,status);
end

function [u,ok,total]=anchor_newton(cfg,u0,d,Kb,il,ir,w1,w2,h1,h2,t1,t2,unload)
ok=false; total=0; n=numel(u0); starts=[u0,d*0.5*ones(n,1),d*0.15*ones(n,1),d*0.85*ones(n,1)];
best=Inf; bestU=u0;
for seed=1:size(starts,2)
 u=starts(:,seed);
 for iter=1:80
  total=total+1;
  [R,J]=anchor_residual(cfg,u,d,Kb,il,ir,w1,w2,h1,h2,t1,t2,unload);
  nr=norm(R,Inf);
  if nr<best, best=nr; bestU=u; end
  if nr<min(1e-5,cfg.force_tol/100), ok=true; return; end
  step=J\R; accepted=false;
  if any(~isfinite(step)), break; end
  scale=1;
  for ls=1:25
   candidate=min(d,max(0,u-scale*step));
   rr=anchor_residual(cfg,candidate,d,Kb,il,ir,w1,w2,h1,h2,t1,t2,unload);
   if norm(rr,Inf)<nr*(1-1e-5*scale)
    u=candidate; accepted=true; break;
   end
   scale=scale/2;
  end
  if ~accepted, break; end
 end
end
u=bestU;
end

function [R,J]=anchor_residual(cfg,u,d,Kb,il,ir,w1,w2,h1,h2,t1,t2,unload)
s1=max(0,u(il)); s2=max(0,d-u(ir));
if unload, m1=h1; m2=h2; else, m1=max(h1,s1); m2=max(h2,s2); end
[~,k1]=bond_law(cfg,m1,t1); [~,k2]=bond_law(cfg,m2,t2);
a1=k1; a2=k2;
if ~unload
 active=s1>h1; soft=active & s1>cfg.bond_slip_max & s1<=cfg.bond_slip_ult;
 a1(soft)=-(t1(soft)-cfg.bond_tau_res)/(cfg.bond_slip_ult-cfg.bond_slip_max); a1(active & s1>cfg.bond_slip_ult)=0;
 active=s2>h2; soft=active & s2>cfg.bond_slip_max & s2<=cfg.bond_slip_ult;
 a2(soft)=-(t2(soft)-cfg.bond_tau_res)/(cfg.bond_slip_ult-cfg.bond_slip_max); a2(active & s2>cfg.bond_slip_ult)=0;
end
n=numel(u); R=Kb*u+accumarray(il,cfg.frp_perim*w1.*k1.*s1,[n 1]) ...
 -accumarray(ir,cfg.frp_perim*w2.*k2.*s2,[n 1]);
J=Kb+spdiags(accumarray([il;ir],cfg.frp_perim*[w1.*a1;w2.*a2],[n 1]),0,n,n);
end

function a=anchor_output(cfg,x1,x2,s1,s2,h1,h2,tm1,tm2,F1,F2,it,ok,status)
[~,k1,z1]=bond_law(cfg,h1,tm1); [~,k2,z2]=bond_law(cfg,h2,tm2);
t1=k1.*s1; t2=k2.*s2; F=(F1+F2)/2;
v1=max(0,F1-cfg.frp_perim*cumtrapz(x1,t1)); v2=max(0,F2-cfg.frp_perim*cumtrapz(x2,t2));
a=struct('force',F,'leftForce',F1,'rightForce',F2,'forceResidual',abs(F1-F2), ...
 'compatibilityResidual',0,'ok',ok,'status',status,'iterations',it,'sides',{{}});
a.sides={struct('x',x1,'slip',s1,'maxSlip',h1,'tau',t1,'tauM',tm1, ...
 'force',v1,'strain',v1/(cfg.frp_E*cfg.frp_area),'zone',z1), ...
 struct('x',x2,'slip',s2,'maxSlip',h2,'tau',t2,'tauM',tm2, ...
 'force',v2,'strain',v2/(cfg.frp_E*cfg.frp_area),'zone',z2)};
end

function [x,weights] = anchor_mesh(cfg,L)

if ~isscalar(L)||~isfinite(L)||L<=0, error('cc19:mesh','Anchor length must be positive.'); 
end
x=linspace(0,L,cfg.n_cells+1)'; 
h=diff(x);
weights=[h(1)/2;(h(1:end-1)+h(2:end))/2;h(end)/2];
end
