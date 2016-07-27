% written by Jianxiong Xiao http://mit.edu/jxiao/

clear;
clc;

% Generating 3000 points in 100 dimensions
X = randn(3000,100);
Y = sign(X(:,1));
n = size(X,1)-100;

lambda = 1;

alwaysKeep = 1:50;

svm_initialize(size(X,2), 0.003, false);

w = [0.1*ones(10,1); zeros(size(X,2)-10,1)];
b = 0;
wMin = [0.1*ones(10,1); zeros(size(X,2)-10,1)];
noneg = 1:10;

w = zeros(size(X,2),1);
b = 0;
wMin = zeros(size(X,2),1);
noneg = [];

for i=1:n
    if Y(i)==1
        c_i = 1;
    else
        c_i = 1;
    end
    if ~ svm_write(X(i,:), Y(i), c_i, wMin);
        svm_prune(alwaysKeep);
    end
    
    [w,b,obj] = svm_optimize(lambda, w, b, wMin, noneg, 2);
    sprintf('obj = %f\n',obj);
end
[w,b,obj] = svm_optimize(lambda, w, b, wMin, noneg, Inf);
sprintf('obj = %f\n',obj);

Y_hat = double((X * w + b)>0)*2-1;

fprintf('training accuracy = %f\n',mean(Y == Y_hat));
