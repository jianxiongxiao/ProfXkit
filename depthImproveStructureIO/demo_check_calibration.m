% this code checks alignment between color and depth
clc
clear 
close all

sequenceName = '2014-04-24_14-29-38';
colorFrameID = 50;
depthFrameID = 50;

maxDepthRange = 10; % in meters

data = loadSUN3Dv2(sequenceName);

image = read(data.image,colorFrameID);   
undistortImage = undistort_image(im2double(image), data.camera.RGB.KK, data.camera.RGB.kc, data.camera.RGB.width, data.camera.RGB.height, data.camera.RGB.K2render);

depth = get_depth(imread(data.depthAll{depthFrameID}));    
XYZcamera(:,:,1)=data.camera.D.X .* depth;
XYZcamera(:,:,2)=data.camera.D.Y .* depth;
XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);    


%{
f = (data.camera.RGB.KK(1,1) + data.camera.RGB.KK(2,2))/2;
data.camera.RGB.KK(1,1) = f;
data.camera.RGB.KK(2,2) = f;
data.camera.RGB.KK(1,3)=data.camera.RGB.width/2;
data.camera.RGB.KK(2,3)=data.camera.RGB.height/2;
%}

[~,imageDepth] = WarpDepthMatlab(XYZcamera, data.camera.RGB.K2render, data.camera.D2RGB.Rt, data.camera.RGB.width, data.camera.RGB.height);


imageDepth(imageDepth(:)>maxDepthRange) = 0;


im = undistortImage;
im(im(:)>1)=1;

im(:,:,4) = imageDepth/maxDepthRange;

figure
imshow(im(:,:,[4 1 3]))



X = reshape(XYZcamera,[],4)';
X = X(1:3,depth(:)>0);
X = transformPointCloud(X,data.camera.D2RGB.Rt);

xy = data.camera.RGB.K2render * X;
xy(1,:) = xy(1,:) ./ xy(3,:) + 1;
xy(2,:) = xy(2,:) ./ xy(3,:) + 1;

figure
subplot(2,1,1);
imshow(im(:,:,[1 2 3]));
hold on;
plot(xy(1,:) , xy(2,:),'.r');
title('points projected on undistorted image');

subplot(2,1,2);
imshow(image);
xyRaw = 1+project_points2(X,data.camera.RGB.fc,data.camera.RGB.cc,data.camera.RGB.kc,data.camera.RGB.alpha_c);
hold on;
plot(xyRaw(1,:) , xyRaw(2,:),'.r');
title('points projected on raw image');