function x = undistort( xd, k, seed )
%[x] = undistort(xd, k)
%INPUT: xd: distorted (normalized) point coordinates in the image plane (2xN matrix)
%       k: Distortion coefficients (radial and tangential) (5x1 vector)
%       seed: (OPTIONAL) seed point corrdinates for undistortion
%       optimization
% Written by Fisher Yu
    
k1 = k(1);
k2 = k(2);
k3 = k(5);
p1 = k(3);
p2 = k(4);

if nargin < 3
  seed = xd;				% initial guess
end

% First undistort with oulu algorithm
x = undistort_oulu(xd, k);

% Find the bad undistorted pixels and refine with better optimization
new_xd = distort(x, k);
errors = sum((xd - new_xd) .^ 2);
badones = errors > 1e-10;
num_badones = sum(badones);
%fprintf('Found %d bad ones\n', num_badones);

if num_badones>0
    options = optimoptions(@fsolve,'Display','off','Jacobian','on',...
      'Algorithm','trust-region-reflective','PrecondBandWidth',1);
    f = @(x) undistort_Jv(x, xd(:, badones), k);
    x(:, badones) = reshape(fsolve(f, seed(:, badones), options), [2, num_badones]);
end


errors = sum((xd - distort(x, k)) .^ 2);
if numel(errors)==424*512
    figure;
    imagesc(reshape(errors,[424 512]));
    axis equal; axis tight; axis off;
    colorbar
end
if numel(errors)==1080*1920
    figure;
    imagesc(reshape(errors,[1080 1920]));
    axis equal; axis tight; axis off;
    colorbar
end

end

function [x] = undistort_oulu(xd, k)
%
%[x] = comp_distortion_oulu(xd,k)
%
%Compensates for radial and tangential distortion. Model From Oulu university.
%For more informatino about the distortion model, check the forward projection mapping function:
%project_points.m
%
%INPUT: xd: distorted (normalized) point coordinates in the image plane (2xN matrix)
%       k: Distortion coefficients (radial and tangential) (5x1 vector)
%
%OUTPUT: x: undistorted (normalized) point coordinates in the image plane (2xN matrix)
%
%Method: Iterative method for compensation.
%
%NOTE: This compensation has to be done after the subtraction
%      of the principal point, and division by the focal length.


if length(k) == 1,
    
    [x] = comp_distortion(xd,k);
    
else
    
    k1 = k(1);
    k2 = k(2);
    k3 = k(5);
    p1 = k(3);
    p2 = k(4);
    
    x = xd; 				% initial guess
    
    for kk=1:20,
        
        r_2 = sum(x.^2);
        k_radial =  1 + k1 * r_2 + k2 * r_2.^2 + k3 * r_2.^3;
        delta_x = [2*p1*x(1,:).*x(2,:) + p2*(r_2 + 2*x(1,:).^2);
        p1 * (r_2 + 2*x(2,:).^2)+2*p2*x(1,:).*x(2,:)];
        x = (xd - delta_x)./(ones(2,1)*k_radial);
            
    end;
    
end;

end

function [F, J] = undistort_J(p, xd, k)

F = distort(p, k) - xd;

if nargout > 1
  J = zeros(2, 2);
  
  x = p(1);
  y = p(2);
  k1 = k(1);
  k2 = k(2);
  k3 = k(5);
  p1 = k(3);
  p2 = k(4);
  
  J(1, 1) = 1+2.*p1.*y+k1.*(x.^2+y.^2)+k2.*(x.^2+y.^2).^2+k3.*(x.^2+y.^2).^3+ ...
    p2.*(4.*x+4.*x.*(x.^2+y.^2))+x.*(2.*k1.*x+4.*k2.*x.*(x.^2+y.^2)+ ...
    6.*k3.*x.*(x.^2+y.^2).^2);
  J(1, 2) = 2.*p1.*x+4.*p2.*y.*(x.^2+y.^2)+x.*(2.*k1.*y+4.*k2.*y.*(x.^2+y.^2)+ ...
    6.*k3.*y.*(x.^2+y.^2).^2);
  J(2, 1) = 2.*p1.*x+2.*p2.*y+y.*(2.*k1.*x+4.*k2.*x.*(x.^2+y.^2)+6.*k3.*x.*( ...
    x.^2+y.^2).^2);
  J(2, 2) = 1+2.*p2.*x+6.*p1.*y+k1.*(x.^2+y.^2)+k2.*(x.^2+y.^2).^2+k3.*(x.^2+ ...
    y.^2).^3+y.*(2.*k1.*y+4.*k2.*y.*(x.^2+y.^2)+6.*k3.*y.*(x.^2+y.^2) ...
    .^2);
end

end

function [F, J] = undistort_Jv(p, xd, k)

%tic
num_points = size(xd, 2);

F = distort(p, k) - xd;

if ~isvector(F)
  F = reshape(F, [numel(F), 1]);
end

if nargout > 1
  
  Jv = zeros(1, num_points * 4);

  k1 = k(1);
  k2 = k(2);
  k3 = k(5);
  p1 = k(3);
  p2 = k(4);

  x = p(1:2:end);
  y = p(2:2:end);

  r2 = x .* x + y .* y;
  Jv(1:4:end) = 1+2.*p1.*y+k1.*r2+k2.*r2.^2+k3.*r2.^3+ ...
    p2.*(4.*x+4.*x.*r2)+x.*(2.*k1.*x+4.*k2.*x.*r2+ ...
    6.*k3.*x.*r2.^2);
  Jv(2:4:end) = 2.*p1.*x+4.*p2.*y.*r2+x.*(2.*k1.*y+4.*k2.*y.*r2+ ...
    6.*k3.*y.*r2.^2);
  Jv(3:4:end) = 2.*p1.*x+2.*p2.*y+y.*(2.*k1.*x+4.*k2.*x.*r2+6.*k3.*x.*( ...
    r2).^2);
  Jv(4:4:end) = 1+2.*p2.*x+6.*p1.*y+k1.*r2+k2.*r2.^2+k3.*(x.^2+ ...
    y.^2).^3+y.*(2.*k1.*y+4.*k2.*y.*r2+6.*k3.*y.*r2 ...
    .^2);
  indexes = 1:(num_points * 2);
  is = zeros(1, num_points * 4);
  is(1:2:end) = indexes;
  is(2:2:end) = indexes;
  js = reshape(indexes, [2, num_points]);
  js = [js; js];
  js = reshape(js, [1, numel(js)]);
  
  J = sparse(is, js, Jv, num_points * 2, num_points * 2, num_points * 4);

end

%fprintf('Undistort_Jv took %f seconds\n', toc);

end

