function [ delta,tao,sigma_1,lamda_1,lamda_2 ] = dts( delta_1,x,L,a,tao_ft,delta_ft,d,A1,Gc,E1,b2,t2,E2 )
%DTS Summary of this function goes here
%   Detailed explanation goes here

    %% Calculate Lamda's
    lamda=sqrt(tao_ft^2/2/Gc*pi*d/A1*(1/E1+A1/E2/b2/t2));
%     lamda=sqrt(tao_ft^2/2/Gc/1.738*(1/E1+A1/E2/b2/t2));
    lamda_1=sqrt(lamda^2*2*Gc/delta_1/tao_ft);
    lamda_2=sqrt(lamda^2*2*Gc/(delta_ft-delta_1)/tao_ft);
    
    %%
    C=lamda_1/lamda_2*delta_1*tanh(lamda_1*(L-a));
    D=delta_1-delta_ft;
       
if x<=L-a
    delta=delta_1*cosh(lamda_1*x)/cosh(lamda_1*(L-a));
    tao=tao_ft/delta_1*delta;
    sigma_1=tao_ft*pi*d/A1/lamda_1*sinh(lamda_1*x)/cosh(lamda_1*(L-a));
else if x<=L
    delta=C*sin(lamda_2*(x-L+a))+D*cos(lamda_2*(x-L+a))+delta_ft;
    tao=max(0,-tao_ft/(delta_ft-delta_1)*(delta-delta_ft));
    sigma_1=tao_ft*lamda_2/delta_ft*pi*d/A1/lamda^2*(C*cos(lamda_2*(x-L+a))-...
    D*sin(lamda_2*(x-L+a)));
    else delta=0;tao=0;sigma_1=0;
    end
end

end

