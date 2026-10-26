function [delta, tao, F2, w, Ls, Ld] = stg1( C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz,Lb )
%STG1 Summary of this function goes here
%   Detailed explanation goes here

    for delta_max=0:0.02:1
        delta_max=delta_max*delta_m;
        M=mnt( N,P,L,z0 );
        delta=delt( C1,C2,Y1,Y2,P,D1,D2,N,delta_max,delta_u,delta_m,c2,L,tao_m0,0,0,zi,z0,tao_r,Lb );
        tao=tao_( N,tao_m0,delta_m,delta,delta_u,tao_r );
        F2=F2_( N,c2,tao,dz );
        [w,w2]= def( M,F2,Y1,Y2,D1,D2,N,dz );
        if F2(1)*(Y1-Y2)*k/P/L*6>=1
            break
        end
    end
    Ls=0;
    Ld=0;
end

