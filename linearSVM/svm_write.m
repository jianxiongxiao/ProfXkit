% written by Jianxiong Xiao http://mit.edu/jxiao/

function success = svm_write(x, y, c, wMin)
% add one example to the training cache

global X
global Y
global n
global D

if n==size(X,1)
    % SVM cache is full. Fail to add more training example
    success = false;
else
    n = n+1;
    X(n,:) = x;
    Y(n) = sqrt(c) * y;
    D(n) = sqrt(c) * (1- y * x * wMin(1:size(X,2)));
    success = true;
end

% We aim to solve the following SVM optimization problem
% min_{w,e}  lambda/2 * ||(w-wMin)||^2 + 1/2 sum_i c_i e_i^2
%      s.t.  y_i * (w .* X_i + b) >= 1 - e_i
%
% let  v = (w-wMin)
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i c_i e_i^2
%      s.t.  y_i * ((v+wMin) .* X_i + b) >= 1 - e_i
% let out_i = sqrt(c_i) e_i
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i out_i^2
%      s.t.  y_i * ((v+wMin) .* X_i + b) >= 1 - out_i/sqrt(c_i)
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i out_i^2
%      s.t.  y_i * (v X_i + wMin X_i + b) >= 1 - out_i/sqrt(c_i)
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i out_i^2
%      s.t.  y_i * (v X_i + b) >= (1- y_i *wMin X_i) - out_i/sqrt(c_i)
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i out_i^2
%      s.t.  sqrt(c_i) * y_i * (v X_i + b) >= sqrt(c_i) * (1- y_i *wMin X_i) - out_i
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i out_i^2
%      s.t.  (sqrt(c_i) * y_i) * (v X_i + b) >= (sqrt(c_i) * (1- y_i *wMin X_i)) - out_i

% input transform
% Y_i = sqrt(c_i) * y_i;
% D_i = sqrt(c_i) * (1- y_i * wMin X_i);
% vInit = wInit - wMin;

% output transform
% w = v+wMin;

% [v,b,sv,obj] = linear_primal_svm(lambda,vInit,D, noneg, maxIteration);
% min_{w,e}  lambda/2 * v'v  + 1/2 sum_i out_i^2
%      s.t.  Y_i * (v .* X_i + b) >= D_i - out_i
