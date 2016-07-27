function [C,K,mu]=autocalibration_lin(PP);

% Function:
% Assuming K_i = diag([fi fi 1]), perform metric upgrade by solving a
% linear system of equation using singular value decomposition.
%
% Input Parameters:
% PP = Vector of P_i
%
% Return Values:
% C  = The absolute conic
% K  = Vector of K_i
% mu = Vector of mu_i
%
% Notation:
% P_i * C * P_i' = mu_i*K_i*K_i' = diag([a_i a_i b_i])
% a_i = mu_i * f_i * f_i
% b_i = mu_i
% C = [ c1 c2 c3 c4  ]
%     [ c2 c5 c6 c7  ]
%     [ c3 c6 c8 c9  ]
%     [ c4 c7 c9 c10 ]
%
% Authors:
% Original By
% Mathematical Imaging Group,
% Centre for Mathematical Sciences, Lund university, SWEDEN. 
% E-mail: kalle@maths.lth.se
%
% Modified By 
% XIAO Jianxiong
% Homepage: http://ihome.ust.hk/~csxjx/
% Vision and Graphics Laboratory, 
% Department of Computer Science and Engineering,
% The Hong Kong University of Science and Technology,
% Hong Kong

% Make up the system of equation Ax=0
% where x = [ c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 a1 a2 ... a_nn b1 b2 ... b_nn]'
E=eye(10);
nn=size(PP,3);	% number of cameras
for i=1:nn,
	ii = (1:6) + (i-1)*6;
	P=PP(:,:,i);
	for j=1:10;
		A( ii , j )	= m2v( P*v2m(E(:,j))*P' );
	end;
	A(ii,10 + i)		= - [1 0 1 0 0 0]';
	A(ii,10 + nn + i)	= - [0 0 0 0 0 1]';
end;

% singular value decomposition
[u,s,v]=svd(A);

% Check that the singular values permit a solution by two conditions:
% 1. Is the smallest singular value small?
% 2. Is the next larger one sufficiently large?
ss = diag(s);       % singular value
N  = size(ss,1);
ok = (ss(N-1) > 10^(-6)) & (ss(N-1)/ss(N) > 10);

if ok
	% Select scale of x so that norm(C,'fro')=1.
		x = v(:,size(v,2));	% x is equal to the last column of v
		C = v2m(x(1:10));
		factor = sign(sum(trace(C)))/norm(C,'fro');
		x = x*factor;
	% Calculate C
		C = v2m(x(1:10));
		[u,s,v]=svd(C); s(4,4)=0; C = u*s*v';
	% Calculate K and mu
		mu = zeros(1,nn);
		K = zeros(3,3,nn);
		for i = 1:nn;
			ai=x(10+i);
			bi=x(10+nn+i);
			mu(i) = bi;
			fi = sqrt(ai/bi);
			K(:,:,i) = diag([fi fi 1]);
		end;
else
	error('The singular values are not good enough to be used to perform auto-calibration');
	K	= NaN*zeros(3,3,nn);
	C	= NaN*zeros(4,4);
	mu	= NaN*zeros(1,nn);
end;
