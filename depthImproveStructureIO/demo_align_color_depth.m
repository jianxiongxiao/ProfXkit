% this code checks alignment between color and depth
clc
clear 
close all

sequenceName = '2014-04-24_14-29-38';
colorFrameID = 20;
depthFrameID = 100;

maxDepthRange = 10; % in meters

data = loadSUN3Dv2(sequenceName);

image = read(data.image,colorFrameID);   

depth = get_depth(imread(data.depthAll{depthFrameID}));    
XYZcamera(:,:,1)=data.camera.D.X .* depth;
XYZcamera(:,:,2)=data.camera.D.Y .* depth;
XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);    
Rt = [data.camera.D2RGB.R data.camera.D2RGB.T];

%f = (data.camera.RGB.KK(1,1) + data.camera.RGB.KK(2,2))/2;
%{
data.camera.RGB.KK(1,1) = f;
data.camera.RGB.KK(2,2) = f;
data.camera.RGB.KK(1,3)=data.camera.RGB.width/2;
data.camera.RGB.KK(2,3)=data.camera.RGB.height/2;
%}
%K2render = round([f 0 data.camera.RGB.width/2; 0 f data.camera.RGB.height/2; 0 0 1]);

[~,imageDepth] = WarpDepthMatlab(XYZcamera,data.camera.RGB.K2render, Rt, data.camera.RGB.width, data.camera.RGB.height);
undistortImage = undistort_image(im2double(image), data.camera.RGB.KK, data.camera.RGB.kc, data.camera.RGB.width, data.camera.RGB.height,data.camera.RGB.K2render);


imageDepth(imageDepth(:)>maxDepthRange) = 0;


im = undistortImage;
im(im(:)>1)=1;

im(:,:,4) = imageDepth/maxDepthRange;

figure
imshow(im(:,:,[1 4 3]))





X = reshape(XYZcamera,[],4)';
X = X(1:3,depth(:)>0);
X = transformPointCloud(X,Rt);

X = data.camera.RGB.K2render * X;
X(1,:) = X(1,:) ./ X(3,:) ;
X(2,:) = X(2,:) ./ X(3,:) ;

figure
imshow(im(:,:,[1 2 3]));
hold on;
plot(X(1,:) , X(2,:),'.r');

