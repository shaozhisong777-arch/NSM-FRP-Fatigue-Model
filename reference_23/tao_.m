function [ stress ] = tao_( N,tao_m,delta_m,delta,delta_u,tao_r )
%TAO Summary of this function goes here
%   Detailed explanation goes here

for i=1:N
    stress(i)=tao_m(i)/delta_m*delta(i)*(delta(i)<=delta_m)*(delta(i)>0)+((delta_u-delta(i))...
        *(tao_m(i)-tao_r)/(delta_u-delta_m)+tao_r)*(delta(i)>delta_m)*(delta(i)<=delta_u)+tao_r*(delta(i)>delta_u);
end

end

