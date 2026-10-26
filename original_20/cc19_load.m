function [M,V] = cc19_load(p,x,Q)
% x from left to calculate; 0<=x<=span。
if nargin<3, Q=p.Qmax; end
if any(x(:)<0)||any(x(:)>p.span), error('cc19:load','x is outside the span.'); 
end
M=(Q/2)*min(min(x,p.span-x),p.shearSpan);
V=zeros(size(x)); 
V(x<p.shearSpan)=Q/2; 
V(x>p.span-p.shearSpan)=-Q/2;
end
