clear all
close all
clc

%% Define RC beam
b1=140;                                 % Width of the RC beam, mm
h1=260;                                 % Height of the RC beam, mm
d3=12;                                  % Diameter of the steel rebar, mm
E1=30000;                               % Young's modulus of the concrete, MPa
E3=205000;                              % Young's modulus of the steel rebar, MPa
A1=b1*h1;                               % Section area of the RC beam, mm2
A3=1/4*pi*d3^2*3;                       % Section area of the steel rebar, mm2
Y1=(A1*h1/2+(E3/E1-1)*A3*40)/(A1+(E3/E1-1)*A3);              % Location of the neutral axis, mm
I1=1/12*b1*h1^3+A1*(h1/2-Y1)^2+(E3/E1-1)*A3*(Y1-40)^2;       % Moment of Inertia of concrete beams, mm
D1=E1*I1;                               % Flexural stiffness of the concrete beam, N.mm
C1=E1*(A1-15*25+(E3/E1-1)*A3);          % Axial stiffness of the concrete beam, N
C3=E3*A3;
L=2300;                               % Clearance, mm
Lb=900;

%% Define FRP
t2=1.4;
h2=20;
c2=2*(t2+h2);                           % Circumference of the CFRP rod, mm
E2=212000;                              % Young's modulus of the CFRP rod, MPa
A2=1.4*20;                              % Section area of the CFRP rod, mm2
Y2=25/2;                                % Location of the neutral axis, mm
I2=1/12*t2*h2^3;                        % Moment of inertia of the CFRP rod, mm4
C2=E2*A2;                               % Axial stiffness of the CFRP rod, N
D2=E2*I2;                               % Flexural stiffness of the CFRP rod, N.mm

%% Define mesh
dz=10;
z0=0:dz:L/2;
zi=z0+dz/2;
N=size(z0);
N=N(2);

%% Define Bond-slip
tao_m=15.72;
tao_m0=tao_m*ones(1,N);
tao_r=1.53;
delta_m=.2;                             % slip when bond strength occurs, mm
delta_u=.7;                             % slip when bond stress becomes zero, mm
count=zeros(1,N);

%% Define Fatigue Loading
P=97900;
n=400;
foc=250;
k=10.56;
Ld=0;

%% Calculate Fatigue Behavior
for i=1:n
    
    %% Calculate critical loading
    Pe(i)=Pe_(N,L,Y1,Y2,D1,D2,delta_m,tao_m0,delta_u,c2,dz,C1,C2,zi,k,z0,tao_r,Lb);
    Ps(i)=Ps_(N,L,Y1,Y2,D1,D2,delta_m,tao_m0,delta_u,c2,dz,C1,C2,zi,k,z0,tao_r,Pe(i),Lb);
    
    %% Calculate flexural behavior
    if P<=Pe(i)
        [delta(i,:),tao(i,:),F2(i,:),w(i,:),Ls(i),Ld(i)] = stg1(C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz,Lb);
    elseif P<=Ps(i)
        [delta(i,:),tao(i,:),F2(i,:),w(i,:),Ls(i),Ld(i)] = stg2(C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz,Pe(i),Ps(i),Lb);
    else
        [delta(i,:),tao(i,:),F2(i,:),w(i,:),Ls(i),Ld(i)] = stg3(C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz,Pe(i),Ps(i),Lb);
    end
    
    %% Update bond strength
    pt=find(delta(i,:)>.75*delta_m);
    pt=max(pt);
    for j=1:pt
        if count(j)==0
            count(j)=i;
        end
    end
    for j=1:N
        if count(j)~=0
            tao_m0(j)=max(tao_r,tao_m*(1-.1965*log10(foc*(1+i-count(j)))));
        end
    end
    a(i)=Ls(i)+Ld(i);
    if a(i)>L*.5
        break
    end
    
    %% Update residual bond strength
    tao_r=max(.863,11.875*(-2.59*log10(foc*i)+12.004));
end
tao=tao';
F2=F2';
w=-w*4.5;
epsilon=F2/C2*1e6;
w1=w(1:5:end,1);
w2=w(1:5:end,58);
w3=w(1:5:end,116);