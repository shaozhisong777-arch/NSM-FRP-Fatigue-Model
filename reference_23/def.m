function [ w,w2 ] = def( M,F2,Y1,Y2,D1,D2,N,dz )
%DEF Summary of this function goes here
%   Detailed explanation goes here
w2=(F2*(Y1-Y2)-M)/(D1+D2);
w1(1)=0;
for i=2:N
    w1(i)=w1(i-1)+w2(i)*dz;
end
w(N)=0;
for i=N-1:-1:1
    w(i)=w(i+1)+w1(i)*dz;
end
end

