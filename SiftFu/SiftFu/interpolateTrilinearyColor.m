function c = interpolateTrilinearyColor(X,Y,Z)

% Trilinear interpolation
% http://en.wikipedia.org/wiki/Trilinear_interpolation

global tsdf_color;

X0=floor(X);    X1=X0+1;
Y0=floor(Y);    Y1=Y0+1;
Z0=floor(Z);    Z1=Z0+1;

Xd = X-X0;  Xdi=1-Xd;
Yd = Y-Y0;  Ydi=1-Yd;
Zd = Z-Z0;  Zdi=1-Zd;

colorArray=[ ...
typecast(tsdf_color(X0,Y0,Z0),'uint8'); ...
typecast(tsdf_color(X0,Y0,Z1),'uint8'); ...
typecast(tsdf_color(X0,Y1,Z0),'uint8'); ...
typecast(tsdf_color(X0,Y1,Z1),'uint8'); ...
typecast(tsdf_color(X1,Y0,Z0),'uint8'); ...
typecast(tsdf_color(X1,Y0,Z1),'uint8'); ...
typecast(tsdf_color(X1,Y1,Z0),'uint8'); ...
typecast(tsdf_color(X1,Y1,Z1),'uint8')];

c = zeros(3,1);

for channel=1:3


    c00 = double(colorArray(4*0+2*0+0+1,channel))*Xdi + double(colorArray(4*1+2*0+0+1,channel))*Xd;
    c10 = double(colorArray(4*0+2*1+0+1,channel))*Xdi + double(colorArray(4*1+2*1+0+1,channel))*Xd;
    c01 = double(colorArray(4*0+2*0+1+1,channel))*Xdi + double(colorArray(4*1+2*0+1+1,channel))*Xd;
    c11 = double(colorArray(4*0+2*1+1+1,channel))*Xdi + double(colorArray(4*1+2*1+1+1,channel))*Xd;

    c0 = c00*Ydi + c10*Yd;
    c1 = c01*Ydi + c11*Yd;

    c(channel,1) = c0*Zdi + c1*Zd;

end
