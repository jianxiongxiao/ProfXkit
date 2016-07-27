

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
%      s.t.  y_i * (v X_i + b) >= (1- Y_i *wMin X_i) - out_i/sqrt(c_i)
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i out_i^2
%      s.t.  sqrt(c_i) * y_i * (v X_i + b) >= sqrt(c_i) * (1- Y_i *wMin X_i) - out_i
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i out_i^2
%      s.t.  (sqrt(c_i) * y_i) * (v X_i + b) >= (sqrt(c_i) * (1- Y_i *wMin X_i)) - out_i

% input transform
Y_i = sqrt(c_i) * y_i;
dvec_i = sqrt(c_i) * (1- Y_i * wMin X_i);

% output transform
w = v+wMin;

%[w,b,sv,obj] = linear_primal_svm(lambda,wInit,dvec,maxIteration,opt);
% min_{w,e}  lambda/2 * v'v  + 1/2 sum_i out_i^2
%      s.t.  Y_i * (v .* X_i + b) >= dvec_i - out_i






% assume c_i is always 1
% min_{w,e}  lambda/2 * ||(w-wMin)||^2 + 1/2 sum_i e_i^2
%      s.t.  Y_i * (w .* X_i + b) >= 1 - e_i
% let  v = (w-wMin)
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i e_i^2
%      s.t.  Y_i * ((v+wMin) .* X_i + b) >= 1 - e_i
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i e_i^2
%      s.t.  Y_i * (v .* X_i + b) >= 1 - Y_i * wMin .* X_i - e_i

[w,b,sv,obj] = linear_primal_svm(lambda,wInit,dvec,maxIteration,opt);
% min_{w,e}  lambda/2 * w'w  + 1/2 sum_i out_i^2
%      s.t.  Y_i * (w .* X_i + b) >= dvec - out_i




% aim to solve the following:
% min_{w,e}  ||(w-w0)*r||^2 + sum_i c_i e_i
%      s.t.  y_i * (w x_ij + b) >= 1 - e_i
%
% min_{w,e}  ||(w-w0)*r||^2 + sum_i c_i e_i
%      s.t.   ([w b] [y_i * x_ij y_i]) >= 1 - e_i
%
% min_{w,e}  ||(w-w0)*r||^2 + sum_i c_i e_i
%      s.t.   w (y_i * x_ij) >= 1 - e_i
%
% min_{w,e}  ||(w-w0)*r||^2 + sum_i c_i e_i
%      s.t.  w x_ij >= 1 - e_i
%
% We can write the above QP in "standard" form:
%
% min_{v,e}  ||v||^2 + sum_i e_i
%      s.t. v x'_ij >= d'_ij - e_i
%
% where  v = (w-w0).*r
%        x'_ij = c_i*(x_ij/r_j)
%        d'_ij = c_i*(1 - w0*x_ij)



% min_{w,e}  r * ||(w-w0)||^2  + sum_i c_i e_i
%      s.t.  w x_ij >= 1 - e_i

% min_{v,e}  r * ||v||^2 + sum_i e_i
%      s.t. v x'_ij >= d'_ij - e_i
%
% where  v = (w-w0)
%        x'_ij = c_i*(x_ij)
%        d'_ij = c_i*(1 - w0*x_ij)
%
% where  v = (w-w0)
%        x'_ij = c_i*(y_i * x_ij)
%        d'_ij = c_i*(1 - w0*y_i * x_ij)



% min_{w,e}  r * ||(w-w0)||^2  + sum_i c_i e_i
%      s.t.  w' x_i >= 1 - e_i

% min_{v,e}  r * ||v||^2 + sum_i e_i
%      s.t. v x'_i >= d'_i - e_i
%
% where  v = (w-w0)
%        x'_i = c_i*(x_i)
%        d'_i = c_i*(1 - w0*x_i)
%
% where  v = (w-w0)
%        x'_i = c_i*(y_i * x_ij)
%        d'_i = c_i*(1 - w0*y_i * x_ij)



% min_{w,e}  lambda/2 * ||(w-wMin)||^2 + 1/2 sum_i c_i e_i^2
%      s.t.  Y_i * (w .* X_i + b) >= 1 - e_i
% let  v = (w-wMin)
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i c_i e_i^2
%      s.t.  Y_i * ((v+wMin) .* X_i + b) >= 1 - e_i
% let E_i = sqrt(c_i) e_i
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i E_i^2
%      s.t.  Y_i * ((v+wMin) .* X_i + b) >= 1 - E_i/sqrt(c_i)
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i E_i^2
%      s.t.  Y_i * (v X_i + wMin X_i + b) >= 1 - E_i/sqrt(c_i)
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i E_i^2
%      s.t.  Y_i * (v X_i + b) >= (1- Y_i *wMin X_i) - E_i/sqrt(c_i)
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i E_i^2
%      s.t.  sqrt(c_i) * Y_i * (v X_i + b) >= sqrt(c_i) * (1- Y_i *wMin X_i) - E_i
% that is
% min_{w,e}  lambda/2 * v'v + 1/2 sum_i E_i^2
%      s.t.  (sqrt(c_i) * Y_i) * (v X_i + b) >= (sqrt(c_i) * (1- Y_i *wMin X_i)) - E_i
[w,b,sv,obj] = linear_primal_svm(lambda,wInit,dvec,maxIteration,opt);
% min_{w,e}  lambda/2 * w'w  + 1/2 sum_i out_i^2
%      s.t.  Y_i * (w .* X_i + b) >= dvec - out_i




