function k = cc19_curvature_integrals(p,q)
% calculate the curvature
y=linspace(0,p.crackHeight,101)'; g=(1-y/p.crackHeight).^p.crackShapeExponent;
w=q/p.kinematicDenominator; v=p.slidingRatio*w;
k=struct('y',y,'shape',g,'opening',w*g,'sliding',v*g, ...
 'verticalJump',q*g,'horizontalJump',(-w*sin(p.theta)+v*cos(p.theta))*g, ...
 'wMax',w,'vMax',v,'q',q);
end
