function [ P ] = Ps_( N,L,Y1,Y2,D1,D2,delta_m,tao_m0,delta_u,c2,dz,C1,C2,zi,k,z,tao_r,Pe,Lb )
%PS_ Summary of this function goes here
%   Detailed explanation goes here

P=Pe;
for j=1:100
    for i=1:100
        Ls=3*i;
        delta=delt( C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_u,delta_m,c2,L,tao_m0,0,0,zi,z,tao_r,Lb );
        if (delta(1)-delta_u)/delta_u<.03
            break
        end
    end
    tao=tao_( N,tao_m0,delta_m,delta,delta_u,tao_r );
    F2=F2_( N,c2,tao,dz );
    Ps=F2(1)*(Y1-Y2)/L*6*k;
    P=P/2+Ps/2;
    if abs(P-Ps)/Ps<.01
        break
    end
end
end