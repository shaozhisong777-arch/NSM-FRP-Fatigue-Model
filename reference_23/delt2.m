function [ out ] = delt2( N,z,Ls,C1,C2,F2,dz,Y1,Y2,w2,pt )
%DELT2 Summary of this function goes here
%   Detailed explanation goes here

out=0;
for i=N:-1:pt
    if z(i)<Ls
        break
    end
    out=out+(1/C1+1/C2)*F2(i)*dz+Y2*w2(i)*dz;
end
end