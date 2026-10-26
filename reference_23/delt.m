function [ slip ] = delt( C1,C2,Y1,Y2,P,D1,D2,N,delta_0,delta_u,delta_m,c2,L,tao_m0,Ls,Ld,zi,z,tao_r,Lb )
%DELT Summary of this function goes here
%   Detailed explanation goes here

if (Ld==0)*(Ls==0)==1
    slip(1)=delta_0;
    lamda_1(1)=sqrt(c2*tao_m0(1)/delta_m*(1/C1+1/C2+(Y1-Y2)^2/(D1+D2)));
    delta_p(1)=0;
    for i=2:N
        lamda_1(i)=sqrt(c2*tao_m0(i)/delta_m*(1/C1+1/C2+(Y1-Y2)^2/(D1+D2)));
        V=0;
        delta_p=-(Y1-Y2)*V/lamda_1(i)^2/(D1+D2);
%         delta(i)=delta(i-1)+(delta_m-delta_p(i))*(exp(lamda_1(i)*(-z0(i)))-exp(lamda_1(i)*(-z0(i-1))))+delta_p(i)-delta_p(i-1);
        slip(i)=(delta_0-delta_p)*exp(lamda_1(i)*(-zi(i)))+delta_p;
    end
end
if (Ld==0)*(Ls~=0)==1
    pt=find(z>Ls);
    pt=pt(1);
    slip(pt)=delta_m;
    lamda_1(pt)=sqrt(c2*tao_m0(pt)/delta_m*(1/C1+1/C2+(Y1-Y2)^2/(D1+D2)));
    V=0;
    delta_p(pt)=-(Y1-Y2)*V/lamda_1(pt)^2/(D1+D2);
    for i=pt+1:N
        lamda_1(i)=sqrt(c2*tao_m0(i)/delta_m*(1/C1+1/C2+(Y1-Y2)^2/(D1+D2)));
        V=0;
        delta_p=-(Y1-Y2)*V/lamda_1(i)^2/(D1+D2);
        slip(i)=(delta_m-delta_p)*exp(lamda_1(i)*(Ls-zi(i)))+delta_p;
    end
    for i=pt-1:-1:1
        lamda_2(i)=sqrt(c2*(tao_m0(i)-tao_r)/(delta_u-delta_m)*(1/C1+1/C2+(Y1-Y2)^2/(D1+D2)));
        lamda_2(i)=lamda_2(i)+.001*(lamda_2(i)==0);
        V=0;
        delta_p=(delta_u*tao_m0(i)-delta_m*tao_r)/(tao_m0(i)-tao_r)-(Y1-Y2)*V/lamda_2(i)^2/(D1+D2);
        C3=delta_0-delta_p;
        C4=(delta_m-delta_p-C3*cos(lamda_2*Ls))/sin(lamda_2*Ls);
        dslip=C3*(cos(lamda_2(i)*z(i+1))-cos(lamda_2(i)*z(i)))+C4*(sin(lamda_2(i)*z(i+1))-sin(lamda_2(i)*z(i)));
        slip(i)=slip(i+1)-dslip;
    end
end
if (Ld~=0)*(Ls~=0)==1
    pt1=find(z>Ls+Ld);
    pt1=pt1(1);
    pt2=find(z>Ld);
    pt2=pt2(1);
    slip(pt1)=delta_m;
    slip(pt2)=delta_u;
    for i=pt1+1:N
            lamda_1(i)=sqrt(c2*tao_m0(i)/delta_m*(1/C1+1/C2+(Y1-Y2)^2/(D1+D2)));
            V=0;
            delta_p=-(Y1-Y2)*V/lamda_1(i)^2/(D1+D2);
            slip(i)=(delta_m-delta_p)*exp(lamda_1(i)*(Ls+Ld-z(i)))+delta_p;
    end
    for i=pt1-1:-1:pt2+1
        lamda_2(i)=sqrt(c2*(tao_m0(i)-tao_r)/(delta_u-delta_m)*(1/C1+1/C2+(Y1-Y2)^2/(D1+D2)));
            lamda_2(i)=lamda_2(i)+.001*(lamda_2(i)==0);
            V=0;
            delta_p=(delta_u*tao_m0(i)-delta_m*tao_r)/(tao_m0(i)-tao_r)-(Y1-Y2)*V/lamda_2(i)^2/(D1+D2);
            temp=[cos(lamda_2(i)*(Ls+Ld)) sin(lamda_2(i)*(Ls+Ld)); cos(lamda_2(i)*Ld) sin(lamda_2(i)*Ld)];
            temp2=[delta_m-delta_p; delta_u-delta_p];
            C=inv(temp)*temp2;
            C3=C(1,1);
            C4=C(2,1);
            dslip=C3*(cos(lamda_2(i)*z(i+1))-cos(lamda_2(i)*z(i)))+C4*(sin(lamda_2(i)*z(i+1))-sin(lamda_2(i)*z(i)));
            slip(i)=slip(i+1)-dslip;
    end
    for i=1:pt2-1
        slip(i)=delta_u+(Ld-z(i))/Ld*(delta_0-delta_u);
    end
end
end
