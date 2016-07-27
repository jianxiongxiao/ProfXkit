% written by Jianxiong Xiao http://mit.edu/jxiao/

clear;
clc;


if true
    %% normal linear problem
    global X;
    global Y;
    global n;
    % Generating 3000 points in 100 dimensions
    X = randn(3000,100);
    Y = sign(X(:,1));
    n = size(X,1)-100;
    
    lambda = 1;
    
    tic
    [w, b,sv,obj]=linear_primal_svm(lambda);
    toc
    tic
    [w, b,sv,obj]=linear_primal_svm(lambda, w, b);
    toc
    
else
    %% Sparse linear problem
    global X;
    global Y;
    global n;
    X = sprandn(1e5,1e4,1e-3);
    Y = sign(sum(X,2)+randn(1e5,1));
    n = size(X,1)-99;
    lambda = 1;
    
    tic
    [w,b,sv,obj]=linear_primal_svm(lambda);
    toc
    tic
    [w, b,sv,obj]=linear_primal_svm(lambda,  w, b);
    toc
end