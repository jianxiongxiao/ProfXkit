close all;
clear

data.camera=load('/Volumes/sun3d/sun3dv2/K4Wv2A1.mat');

depth = double(imread('/Volumes/sun3d/sun3dv2/2014_04_06-16_06_34/for_comparison_mac/depth_0042.png'))/1000;
depth = depth(:,end:-1:1);
%depth(depth(:)>=4.5)=0;


depth =denoise(depth,data.camera.D);


XYZcamera(:,:,1)=data.camera.D.X .* depth;
XYZcamera(:,:,2)=data.camera.D.Y .* depth;
XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));


figure;imagesc(XYZcamera(:,:,3)); axis equal; axis tight;

X = reshape(XYZcamera,[],3);

validID = find(X(:,3)~=0);

X = X(validID,:);


points2ply('filter.ply', X);

return;

points2ply('original.ply', X);


% denoise

kdOBJ = KDTreeSearcher(X);


[match,mindist] = knnsearch(kdOBJ,X,'K',3);

threshold1 = 0.1;
threshold2 = 0.2;
threaholdFurthest = 10;
threaholdClosest = 0.5;

goodones = mindist(:,2)<threshold1 & mindist(:,3)<threshold2 & X(:,3)<threaholdFurthest & X(:,3)>threaholdClosest ;

XYZcamera( 2*data.camera.D.width*data.camera.D.height + validID(~goodones)) = 0;
X = X(goodones,:);

figure;imagesc(XYZcamera(:,:,3)); axis equal; axis tight;


points2ply('filter1.ply', X);


depth3Max = ordfilt2(XYZcamera(:,:,3),23,true(5));

outliers = XYZcamera(:,:,3) > (depth3Max + 0.5) & (depth3Max>0);
XYZcamera( 2*data.camera.D.width*data.camera.D.height + find(outliers)) = 0;

figure;imagesc(XYZcamera(:,:,3)); axis equal; axis tight;

%depthMed = medfilt2(XYZcamera(:,:,3), [5 5]);
%XYZcamera(:,:,3)

X = reshape(XYZcamera,[],3);
validID = find(X(:,3)~=0);
X = X(validID,:);
points2ply('filter2.ply', X);