function [K, R, t] = decomposeP(P)
%VGG_KR_FROM_P Extract K, R from camera matrix.
%
%    [K,R,t] = VGG_KR_FROM_P(P [,noscale]) finds K, R, t such that P = K*R*[eye(3) -t].
%    It is det(R)==1.
%    K is scaled so that K(3,3)==1 and K(1,1)>0. Optional parameter noscale prevents this.
%
%    Works also generally for any P of size N-by-(N+1).
%    Works also for P of size N-by-N, then t is not computed.


% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Modified by werner.
% Date: 15 May 98



N = size(P,1);
H = P(:,1:N);

[K,R] = rq(H);

K = K*sign(K(1));
if prod(sign(diag(K))) < 0
  D = diag(-1*sign(diag(K)));
else
  D = diag(sign(diag(K)));
end
K = K*D;
R = D*R;

K = K/K(end);

% $$$ if nargin < 2
% $$$   K = K / K(N,N);
% $$$   if K(1,1) < 0
% $$$     D = diag([-1 -1 ones(1,N-2)]);
% $$$     K = K * D;
% $$$     R = D * R;
% $$$     
% $$$   %  test = K*R; 
% $$$   %  vgg_assert0(test/test(1,1) - H/H(1,1), 1e-07)
% $$$   end
% $$$ end

if nargout > 2
  t = -P(:,1:N)\P(:,end);
end

return
