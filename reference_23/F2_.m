function [ force ] = F2_( N,c2,tao,dz )
%F2 Summary of this function goes here
%   Detailed explanation goes here
force(N)=0;
for i=N-1:-1:1
    force(i)=force(i+1)+c2*tao(i)*dz;
end
end

