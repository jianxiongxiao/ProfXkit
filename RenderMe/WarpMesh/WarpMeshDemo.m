clear
close all

% for linux
mex WarpMesh.cpp -lGLU -lOSMesa -lGL
% for mac
%mex WarpMesh.cpp -lGLU -lOSMesa -I/opt/X11/include/ -L/opt/X11/lib/

load demo.mat

%{
P=[570.3422         0  320.0000 0
          0  570.3422  240.0000 0
          0         0    1.0000 0];
%}

XYZcamera = double(XYZcamera);

XYZcamera(:,:,1) = - XYZcamera(:,:,1);
XYZcamera(:,:,2) = XYZcamera(:,:,2);
XYZcamera(:,:,3) = XYZcamera(:,:,3);


[label,depth]=WarpMesh(P,640,480,XYZcamera);

label = label';
label = label(:,end:-1:1);
figure
imagesc(label)


depth = depth';
depth = depth(end:-1:1,end:-1:1);

z_near = 0.3;
z_far_ratio = 1.2;
depth = z_near./(1-double(depth)/2^32);
maxDepth = max(depth(abs(depth) < 100));

cropmask = (depth < z_near) | (depth > z_far_ratio * maxDepth);
depth(cropmask) = 0; %NaN;%z_far_ratio * maxDepth;


figure
imagesc(depth)
