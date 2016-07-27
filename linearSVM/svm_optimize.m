function [w,b,obj] = svm_optimize(lambda, wInit, bInit,  wMin, noneg, maxIteration)

% written by Jianxiong Xiao http://mit.edu/jxiao/

global D;
global SV;

% input transform
% Y_i = sqrt(c_i) * y_i;
% D_i = sqrt(c_i) * (1- y_i * wMin X_i);
% vInit = wInit - wMin;
vInit = wInit - wMin;
global n;

if n<2000
    v = vInit;
    b = bInit;
    obj = 0;
else
    [v,b,sv,obj] = linear_primal_svm(lambda,vInit,bInit,D, noneg, maxIteration);
    
    SV = sv;
end

% output transform
w = v+wMin;
