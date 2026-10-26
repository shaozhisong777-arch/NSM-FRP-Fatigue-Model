function [ moment ] = mnt( N,P,L,z )
%MNT Summary of this function goes here
%   Detailed explanation goes here
for i=1:N
    moment(i)=P*L/6*(z(i)<=L/6)+P/2*(L/2-z(i))*(z(i)>L/6);
end

end

