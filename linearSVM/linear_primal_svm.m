function [w,b,sv,obj] = linear_primal_svm(lambda,wInit,bInit,D,noneg, maxIteration,opt)
% Solves the following SVM optimization problem in the primal (with quatratic
%   penalization of the training errors). Default solved by Newton.
%
% min_{w,e}  lambda/2 * w'w  + 1/2 sum_i out_i^2
%      s.t.  Y_i * (w .* X_i + b) >= D_i - out_i
%            w(nonneg)>=0
%
% A global variable X containing the training inputs
%   should be defined. X is an n x d matrix (n = number of points).
%   X can be either normal matrix or sparse matrix.
% A global variable Y is the target vector of size nx1. Normal SVM will
%   have +1 and -1 value, but it can be actually aribitury value
% A global variable n is the number of elements that you want to use for training.
% LAMBDA is the regularization parameter ( = 1/C)
% wInit is an optional input for the initial value of [w;b]
% dvec is an optional input, usually it is 1 for standard SVM
% maxIteration is the number of iterations allowd
%
% W is the hyperplane w (vector of length d).
% B is the bias
% The outputs on the training points are either X*W+B
% SV is the support vector index number
% OBJ is the objective function value
% OPT is a structure containing the options (in brackets default values):
%   cg: Do not use Newton, but nonlinear conjugate gradients [0]
%   lin_cg: Compute the Newton step with linear CG
%           [0 unless solving sparse linear SVM]
%   iter_max_Newton: Maximum number of Newton steps [20]
%   prec: Stopping criterion
%   cg_prec and cg_it: stopping criteria for the linear CG.

% Original written by Olivier Chapelle @ http://olivier.chapelle.cc/primal/
% Modified by Jianxiong Xiao to have several advance features @ http://mit.edu/jxiao/


if ~exist('maxIteration','var') || maxIteration==Inf     % Assign the options to their default values
    maxIteration = 10000000;
end

if ~exist('opt','var')       % Assign the options to their default values
    opt = [];
end
if ~isfield(opt,'cg'),                opt.cg = 0;                        end;
if ~isfield(opt,'lin_cg'),            opt.lin_cg = 0;                    end;
if ~isfield(opt,'iter_max_Newton'),   opt.iter_max_Newton = 20;          end; % used to be 20
if ~isfield(opt,'prec'),              opt.prec = 1e-6;                   end;
if ~isfield(opt,'cg_prec'),           opt.cg_prec = 1e-4;                end;
if ~isfield(opt,'cg_it'),             opt.cg_it = 20;                    end;


global X;
global Y;

if ~exist('noneg','var')
    noneg = [];
end

if ~exist('dvec','var') || isempty(D)
    D = ones(numel(Y),1);
end

if isempty(X), error('Global variable X undefined'); end;

if ~exist('bInit','var')
    bInit=0;
end
if ~exist('wInit','var')
    d = size(X,2);
    wInit = zeros(d,1);
end
if issparse(X)
    opt.lin_cg = 1;
end;
if ~opt.cg
    [sol,obj, sv] = primal_svm_linear   (lambda,maxIteration,wInit,bInit,D,noneg,opt);
else
    [sol,obj, sv] = primal_svm_linear_cg(lambda,maxIteration,wInit,bInit,D,noneg,opt);
end;

% The last component of the solution is the bias b.
b = sol(end);
w = sol(1:end-1);
fprintf('\n');


% -------------------------------
% Train a linear SVM using Newton
% -------------------------------
function  [w,obj,sv] = primal_svm_linear(lambda,maxIteration,wInit,bInit,D,noneg,opt)

global X;
global Y;
global n;
d = size(X,2);

w = [wInit; bInit]; % The last component of w is b.
w(noneg) = max(w(noneg),0);
%out = ones(n,1); % Vector containing 1-Y.*(X*w)
out = D(1:n) - Y(1:n).*(X(1:n,:)*w(1:end-1)+w(end));

for iter=1:maxIteration
    if iter > opt.iter_max_Newton;
        warning('PrimalSVM:MaxNumNewton','Maximum number of Newton steps reached. Try larger lambda');
        break;
    end;
    
    [obj, grad, sv] = obj_fun_linear(w,lambda,out);
    
    % Compute the Newton direction either exactly or by linear CG
    if opt.lin_cg
        % Advantage of linear CG when using sparse input: the Hessian is never computed explicitly.
        [step, foo, relres] = minres(@hess_vect_mult, -grad, opt.cg_prec,opt.cg_it,[],[],[],sv,lambda);
    else
        Xsv = X(sv,:);
        hess = lambda*diag([ones(d,1); 0]) + [[Xsv'*Xsv sum(Xsv,1)']; [sum(Xsv) length(sv)]];   % Hessian
        step  = - hess \ grad;   % Newton direction
    end;
    
    % Do an exact line search
    [t,out, sv] = line_search_linear(w,step,out, lambda);
    
    w = w + t*step;
    w(noneg) = max(w(noneg),0);
    fprintf('Iter = %d, Obj = %f, Nb of sv = %d, Newton decr = %.3f,  Line search = %.3f',iter,obj,length(sv),-step'*grad/2,t);
    if opt.lin_cg
        fprintf(', Lin CG acc = %.4f     \n',relres);
    else
        fprintf('      \n');
    end;
    
    if -step'*grad < opt.prec * obj
        % Stop when the Newton decrement is small enough
        break;
    end;
end;



% -----------------------------------------------------
% Train a linear SVM using nonlinear conjugate gradient
% -----------------------------------------------------
function  [w, obj, sv] = primal_svm_linear_cg(lambda,maxIteration,wInit,bInit, D,noneg,opt)
global X;
global Y;
global n;
d = size(X,2);

w = [wInit; bInit]; % The last component of w is b.
w(noneg) = max(w(noneg),0);
%out = ones(n,1); % Vector containing 1-Y.*(X*w)
out = D(1:n) - Y(1:n).*(X(1:n,:)*w(1:end-1)+w(end));

%go = [X(1:n,:)'*Y(1:n); sum(Y(1:n))];  % -gradient at w=0, need to be change for w!=0 initialization
[~, grad] = obj_fun_linear(w,lambda,out); go = -grad; % -gradient


s = go; % The first search direction is given by the gradient
for iter=1:maxIteration
    if iter > opt.cg_it * min(n,d)
        warning('PrimalSVM:MaxNumCG','Maximum number of CG iterations reached. Try larger lambda');
        break;
    end;
    
    % Do an exact line search
    [t,out,sv] = line_search_linear(w,s,out,lambda);
    w = w + t*s;
    w(noneg) = max(w(noneg),0);
    
    % Compute the new gradient
    [obj, gn, sv] = obj_fun_linear(w,lambda,out); gn=-gn;
    fprintf('Iter = %d, Obj = %f, Norm of grad = %.3f     \n',iter,obj,norm(gn));
    
    % Stop when the relative decrease in the objective function is small
    if t*s'*go < opt.prec*obj, break; end;
    
    % Flecher-Reeves update. Change 0 in 1 for Polack-Ribiere
    be = (gn'*gn - 0*gn'*go) / (go'*go);
    s = be*s+gn;
    go = gn;
end;





function [obj, grad, sv] = obj_fun_linear(w,lambda,out)
% Compute the objective function, its gradient and the set of support vectors
% Out is supposed to contain 1-Y.*(X*w)
global X;
global Y;
global n;
out = max(0,out);
wb0 = w; wb0(end) = 0;  % Do not penalize b <= Very important for object detection
obj = sum(out.^2)/2 + lambda*(wb0')*wb0/2; % L2 penalization of the errors
grad = lambda*wb0 - [((out.*Y(1:n))'*X(1:n,:))'; sum(out.*Y(1:n))]; % Gradient
sv = find(out>0);


function [t,out,sv] = line_search_linear(w,d,out,lambda)
% From the current solution w, do a line search in the direction d by
% 1D Newton minimization
global X;
global Y;
global n;
t = 0;
% Precompute some dots products
Xd = X(1:n,:)*d(1:end-1)+d(end);
wd = lambda * w(1:end-1)'*d(1:end-1);
dd = lambda * d(1:end-1)'*d(1:end-1);
while 1
    out2 = out - t*(Y(1:n).*Xd); % The new outputs after a step of length t
    sv = find(out2>0);
    g = wd + t*dd - (out2(sv).*Y(sv))'*Xd(sv); % The gradient (along the line)
    h = dd + Xd(sv)'*Xd(sv); % The second derivative (along the line)
    t = t - g/h; % Take the 1D Newton step. Note that if d was an exact Newton
    % direction, t is 1 after the first iteration.
    if g^2/h < 1e-10, break; end;
    %    fprintf('%f %f\n',t,g^2/h)
end;
out = out2;



function y = hess_vect_mult(w,sv,lambda)
% Compute the Hessian times a given vector x.
% hess = lambda*diag([ones(d-1,1); 0]) + (X(sv,:)'*X(sv,:));
global X;
global n;
y = lambda*w;
y(end) = 0;
z = (X(1:n,:)*w(1:end-1)+w(end));  % Computing X(sv,:)*x takes more time in Matlab :-(
zz = zeros(length(z),1);
zz(sv)=z(sv);
y = y + [(zz'*X(1:n,:))'; sum(zz)];




