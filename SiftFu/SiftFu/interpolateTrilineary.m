function c = interpolateTrilineary(X,Y,Z)

if nargin == 1
   pos = X;
   X = pos(1);
   Y = pos(2);
   Z = pos(3);
end


% Trilinear interpolation
% http://en.wikipedia.org/wiki/Trilinear_interpolation


global tsdf_value;

%tic; interp3(tsdf_value,X,Y,Z); toc

% compile>> mex -O ba_interp3single.cpp

%c = ba_interp3single(tsdf_value,single(Y),single(X),single(Z));

%return;

%tic
X0=floor(X);    X1=X0+1;
Y0=floor(Y);    Y1=Y0+1;
Z0=floor(Z);    Z1=Z0+1;

Xd = X-X0;  Xdi=1-Xd;
Yd = Y-Y0;  Ydi=1-Yd;
Zd = Z-Z0;  Zdi=1-Zd;

c00 = double(tsdf_value(X0,Y0,Z0))*Xdi + double(tsdf_value(X1,Y0,Z0))*Xd;
c10 = double(tsdf_value(X0,Y1,Z0))*Xdi + double(tsdf_value(X1,Y1,Z0))*Xd;
c01 = double(tsdf_value(X0,Y0,Z1))*Xdi + double(tsdf_value(X1,Y0,Z1))*Xd;
c11 = double(tsdf_value(X0,Y1,Z1))*Xdi + double(tsdf_value(X1,Y1,Z1))*Xd;

c0 = c00*Ydi + c10*Yd;
c1 = c01*Ydi + c11*Yd;

c = c0*Zdi + c1*Zd;
%toc
