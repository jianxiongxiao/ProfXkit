% written by Jianxiong Xiao http://mit.edu/jxiao/
function svm_initialize(dimension, RAMsize, isSparse)

global n;
global X;
global Y;
global D;
global sv;


%{
RAMsize = 8; % max memory
if RAMsize > memoryLinux()*0.50
    RAMsize = min(8,round(memoryLinux()*0.30)); %<- so that we can run two scripts on the same machines
end
fprintf('Using %.1f GB\n',RAMsize);
%}

n = round(RAMsize*1024*1024*1024 / (dimension*8) ); % use 8 byte for double
fprintf('SVM initalize size = %d\n',n);

if isSparse
    X = sparse(n, dimension);
else
    X = zeros(n, dimension);
end
Y = zeros(n,1);
D = ones(n,1);
sv = [];

n = 0;
