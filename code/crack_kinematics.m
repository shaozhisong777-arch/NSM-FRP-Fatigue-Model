function k = crack_kinematics(cfg,q)
% 裂缝张开/滑移几何：q为竖向相对位移，绝不是曲率或跨中挠度。
y=linspace(0,cfg.crack_height,101)'; g=(1-y/cfg.crack_height).^cfg.crack_exp;
w=q/cfg.kinematicDenominator; v=cfg.slide_ratio*w;
k=struct('y',y,'shape',g,'opening',w*g,'sliding',v*g, ...
 'verticalJump',q*g,'horizontalJump',(-w*sin(cfg.theta)+v*cos(cfg.theta))*g, ...
 'wMax',w,'vMax',v,'q',q);
end
