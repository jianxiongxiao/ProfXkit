% written by Jianxiong Xiao http://mit.edu/jxiao/

function svm_prune(alwaysKeep)

global n;
global X;
global Y;
global D;
global SV;

SV = unique([SV; alwaysKeep(:)]);
SV = SV(SV<=n);
n = numel(SV);

X(1:n,:) = X(SV,:);
Y(1:n) = Y(SV,:);
D(1:n) = D(SV);

