function [ delta,tao,F2,w,Ls,Ld ] = stg3( C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz,Pe,Ps,Lb )
%STG2 Summary of this function goes here
%   Detailed explanation goes here

delta_0=delta_m+(P-Pe)/(Ps-Pe)*(delta_u-delta_m);
lamda_2_min=sqrt(c2*max(tao_m0)/(delta_u-delta_m)*(1/C1+1/C2+(Y1+Y2)^2/(D1+D2)));
Ls_max=acos(delta_m/delta_u)/lamda_2_min;
for Ld=1:4:L/2-Ls_max+10
    Ls=Ls_max;
    delta=delt( C1,C2,Y1,Y2,P,D1,D2,N,delta_0,delta_u,delta_m,c2,L,tao_m0,Ls,Ld,zi,z0,tao_r,Lb );
    tao=tao_( N,tao_m0,delta_m,delta,delta_u,tao_r );
    F2=F2_( N,c2,tao,dz );
    M=mnt( N,P,L,z0 );
    [w,~]= def( M,F2,Y1,Y2,D1,D2,N,dz );
    if abs(F2(1)*(Y1-Y2)*k-P*L/6)/P/L*6<.03||F2(1)*(Y1-Y2)*k>P*L/6
        break
    end
end
end