function xd = distort( x, k )
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

k1 = k(1);
k2 = k(2);
k3 = k(5);
p1 = k(3);
p2 = k(4);

if isvector(x)
  x = reshape(x, [2, numel(x) / 2]);
end

r_2 = sum(x.^2);
k_radial =  1 + k1 * r_2 + k2 * r_2.^2 + k3 * r_2.^3;
delta_x = [2*p1*x(1,:).*x(2,:) + p2*(r_2 + 2*x(1,:).^2); p1 * (r_2 + 2*x(2,:).^2)+2*p2*x(1,:).*x(2,:)];
xd = [k_radial; k_radial] .* x + delta_x;

end

