function [ out ] = delt3( delta_m,C1,C2,F2,dz,Y1,Y2,w2,pt )
%DELT3 Summary of this function goes here
%   Detailed explanation goes here

out=delta_m;
for i=pt+1:-1:1
    out=out+(1/C1+1/C2)*F2(i)*dz+(Y1+Y2)*w2(i)*dz;
end
end

