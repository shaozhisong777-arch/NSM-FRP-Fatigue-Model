function a = cc19_paper_interpolation(p,st)
% 旧文件名保留；现只给出均匀应变桁架公式的对照，不再用抗弯阶段插值控制状态。
% 实际求解始终用离散交点轴力之和，不再乘一遍d/s，避免重复计算NSM数量。
if p.nBars==0, v=0; else
 epsMean=mean(st.barForce/(p.Ef*p.Af));
 v=p.nsmFaces*p.Af*p.Ef*epsMean*p.crackHeight/p.nsmSpacing ...
  *(1/tan(p.theta)+1/tan(p.alpha))*sin(p.alpha);
end
a=struct('uniformStrainTrussReference_N',v,'discreteIntersectionSum_N',st.Vnsm, ...
 'usedByStateSolver',false,'note','Truss reference only; actual bar intersections and two-sided anchorage govern the model.');
end
