clear all
close all
clc

%% Define Concrete block
b1=300;                               % Width of the RC beam, mm
h1=150;                               % Height of the RC beam, mm
E1=30000;                               % Young's modulus of the concrete, MPa
E3=200000;                              % Young's modulus of the steel rebar, MPa
A1=b1*h1;                               % Section area of the RC beam, mm2
I1=1/12*b1*h1^3+A1*(h1/2-Y1)^2+(E3/E1-1)*A3*(Y1-40)^2;       % Moment of Inertia of concrete beams, mm
D1=E1*I1;                               % Flexural stiffness of the concrete beam, N.mm
C1=E1*(A1-15*25+(E3/E1-1)*A3);          % Axial stiffness of the concrete beam, N
C3=E3*A3;
L=2745;                               % Clearance, mm

%% Define FRP
d2=6.4;                                  % Diameter of the CFRP rod, mm
c2=pi*d2*2;                               % Circumference of the CFRP rod, mm
E2=150000;                              % Young's modulus of the CFRP rod, MPa
A2=.25*pi*d2^2*2;                               % Section area of the CFRP rod, mm2
Y2=9.5/2;                                % Location of the neutral axis, mm
I2=1/4*pi*(d2/2)^4*2;                     % Moment of inertia of the CFRP rod, mm4
C2=E2*A2;                               % Axial stiffness of the CFRP rod, N
D2=E2*I2;                               % Flexural stiffness of the CFRP rod, N.mm

%% Define mesh
dz=5;
z0=0:dz:L/2;
zi=z0+dz/2;
N=size(z0);
N=N(2);

%% Define Bond-slip
tao_m=13.89;
tao_m0=tao_m*ones(1,N);
tao_r=1.78;
delta_m=.15;                             % slip when bond strength occurs, mm
delta_u=.7;                             % slip when bond stress becomes zero, mm
count=zeros(1,N);

%% Define Fatigue Loading
P=50000;
n=1;

k1=2.61;
k=k1+1;

%% Calculate Fatigue Behavior
for i=1:n
    
    %% Calculate critical loading
    Pe=Pe_(N,L,Y1,Y2,D1,D2,delta_m,tao_m0,delta_u,c2,dz,C1,C2,zi,k,z0,tao_r);
    Ps=Ps_(N,L,Y1,Y2,D1,D2,delta_m,tao_m0,delta_u,c2,dz,C1,C2,zi,k,z0,tao_r,Pe);
    
    %% Calculate flexural behavior
    if P<=Pe
        [delta(i,:),tao(i,:),F2(i,:),w(i,:)] = stg1(C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz);
    elseif P<=Ps
        [delta(i,:),tao(i,:),F2(i,:),w(i,:),Ls(i)] = stg2(C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz,Pe,Ps);
    else
        [delta(i,:),tao(i,:),F2(i,:),w(i,:),Ls(i),Ld(i)] = stg3(C1,C2,Y1,Y2,P,D1,D2,N,delta_u,delta_m,c2,L,tao_m0,zi,z0,tao_r,k,dz,Pe,Ps);
    end
    w=-4*w;
    %% Update bond strength
    pt=find(delta(i,:)>0.75*delta_m);
    pt=max(pt);
    for j=1:pt
        if count(j)==0
            count(j)=i;
        end
    end
    for j=1:N
        if count(j)~=0
            tao_m0(j)=max(tao_r,tao_m*(1-.1965*log10(1+i-count(j))));
        end
    end
end