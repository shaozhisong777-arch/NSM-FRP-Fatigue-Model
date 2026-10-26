function [ delta, tao, N2,delta0 ] = dtN( N,La,Ld,C1,C2,Y1,Y2,D1,D2,d2,tao_m,delta_m,P,z0,L,zi,delta_u,Kr )
%DTN Summary of this function goes here
%   Detailed explanation goes here

N2(N)=0;
for i=N-1:-1:1
    if z0(i)>=La+Ld
        lamda(i)=sqrt((1/C1+1/C2+(Y1+Y2)^2/(D1+D2))*pi*d2*tao_m(i)/delta_m);
        delta_c(i)=(Y1+Y2)/(D1+D2)/lamda(i)^2*P/2*(z0(i)>L/6);
        delta(i)=(delta_m-delta_c(i))*exp(lamda(i)*(La+Ld-zi(i)))+delta_c(i);
        tao(i)=delta(i)/delta_m*tao_m(i);
        N2(i)=N2(i+1)+pi*d2*tao_m(i)/delta_m*(delta_c(i)-delta_m)/lamda(i)*exp(...
            lamda(i)*(La+Ld))*(exp(-lamda(i)*zi(i+1))-exp(-lamda(i)*zi(i))) ...
            +pi*d2*tao_m(i)/delta_m*delta_c(i)*(zi(i+1)-zi(i));
    else
        if z0(i)>=Ld
            lamda(i)=sqrt((1/C1+1/C2+(Y1+Y2)^2/(D1+D2))*pi*d2*tao_m(i)...
                /(delta_u-delta_m));
            delta_c(i)=delta_u+(Y1+Y2)/(D1+D2)/lamda(i)^2*P/2*(z0(i)>L/6);
            K=[cos(lamda(i)*(La+Ld)) sin(lamda(i)*(La+Ld)); ...
                cos(lamda(i)*Ld) sin(lamda(i)*Ld)];
            C=inv(K)*[delta_m-delta_c(i); delta_u-delta_c(i)];
            delta(i)=C(1)*cos(lamda(i)*zi(i))+C(2)*sin(lamda(i)*zi(i))...
                +delta_c(i);
            tao(i)=tao_m(i)/(delta_u-delta_m)*(delta_u-delta(i));
            N2(i)=N2(i+1)+tao_m(i)*pi*d2/(delta_u-delta_m)*(zi(i+1)-zi(i))...
                *(delta_u-delta_c(i))-tao_m(i)*pi*d2/(delta_u-delta_m)/lamda(i)...
                *(C(1)*(sin(lamda(i)*zi(i+1))-sin(lamda(i)*zi(i)))+C(2)*(cos(lamda(i)*zi(i))-cos(lamda(i)*zi(i+1))));
        else
            tao(i)=0;
            N2(i)=N2(i+1);
            delta0=(P*L/6-N2(i)*(Y1+Y2))*Y1/Kr;
            delta(i)=delta_u+(delta0-delta_u)/Ld*(Ld-zi(i));
        end
    end
end
end

