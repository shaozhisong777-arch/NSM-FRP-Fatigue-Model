function a = cc19_shearforce(p,st)
% 2019 sigle crack euqation 12
if p.nBars==0, v=0; else
 epsMean=mean(st.barForce/(p.Ef*p.Af));
 v=p.nsmFaces*p.Af*p.Ef*epsMean*p.crackHeight/p.nsmSpacing ...
  *(1/tan(p.theta)+1/tan(p.alpha))*sin(p.alpha);
end
a=struct('uniformStrainTrussReference_N',v,'discreteIntersectionSum_N',st.Vnsm, ...
 'usedByStateSolver',false,'note','Truss reference only; actual bar intersections and two-sided anchorage govern the model.');
end
