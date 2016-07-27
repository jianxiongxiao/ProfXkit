%% load an RGBD sequence
data = loadSUN3Dv2('2014-05-01_19-32-43_260595134347');

%% demo to show how to use a frame
frameID = 11;

%% load the frame data
image = readImage(data,frameID);
depth = readDepth(data,frameID); % use this to read the denoised depth map that is closet to the image

IR = readIR(data,frameID);

%% get 3D point cloud from the depth map
XYZcamera(:,:,1)=data.camera.D.X .* depth;
XYZcamera(:,:,2)=data.camera.D.Y .* depth;
XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);
valid = logical(XYZcamera(:,:,4));  
valid = valid(:)';        
XYZ = reshape(XYZcamera,[],4)';
XYZ = XYZ(1:3,valid);

points2ply('demo_all_points.ply', XYZ);

%% get the color for each 3D point by tranforming and projecting each 3D point
XYZrgb = transformPointCloud(XYZ,data.camera.D2RGB.Rt);
xyRGB = 1+project_points2(XYZrgb,data.camera.RGB.fc,data.camera.RGB.cc,data.camera.RGB.kc,data.camera.RGB.alpha_c);
uvRGB = round(xyRGB);
valid = 1<= uvRGB(1,:) & uvRGB(1,:) <= data.camera.RGB.width & 1<= uvRGB(2,:) & uvRGB(2,:) <= data.camera.RGB.height;
XYZ = XYZ(1:3,valid);
ind = sub2ind([data.camera.RGB.height data.camera.RGB.width],uvRGB(2,valid),uvRGB(1,valid));
RGB =[image(ind); image(ind+data.camera.RGB.height*data.camera.RGB.width); image(ind+data.camera.RGB.height*data.camera.RGB.width*2)];
points2ply('demo_points_with_color.ply', XYZ, RGB);

%% project the 3D points to the undistort color image
xyzRGBnormal = data.camera.RGB.K2render * XYZrgb;
xyzRGBnormal(1,:) = 1+ xyzRGBnormal(1,:) ./ xyzRGBnormal(3,:);
xyzRGBnormal(2,:) = 1+ xyzRGBnormal(2,:) ./ xyzRGBnormal(3,:);

%% undistort the RGB image into an pin hole camera with data.camera.RGB.K2render as intrinsics
undistortImage = undistort_image(im2double(image), data.camera.RGB.KK, data.camera.RGB.kc, data.camera.RGB.width, data.camera.RGB.height, data.camera.RGB.K2render);

%% undistort the depth map, transform the depth, and project it using OpenGL to the undistorted image with data.camera.RGB.K2render as intrincis
% manually find one
%[~,imageDepth] = WarpDepthMatlab(XYZcamera,data.camera.RGB.K2render, data.camera.D2RGB.Rt, data.camera.RGB.width, data.camera.RGB.height);
% or better to use this one
imageDepth = depth4RGB(data, frameID); % use this to read a depth map that is a combination of the closest two depth map
% another useful function to do the same thing is
% frames = getRGBDframe(sequenceName,frameID);

%% undistort the IR image. Typicaly, you don't need this
undistortIR = undistort_image(im2double(IR), data.camera.D.KK, data.camera.D.kc, data.camera.D.width, data.camera.D.height);

%% undistore the depth map to a pixel camera, and do NOT align it with the RGB image
[~,undistortDepth] = WarpDepthMatlab(XYZcamera,data.camera.D.KK, [eye(3) zeros(3,1)], data.camera.D.width, data.camera.D.height);

%% visualization
figure
subplot(2,3,1);
imagesc(depth);
axis equal; axis tight; axis off;
title('raw depth');

subplot(2,3,2);
imshow(image);
hold on;
plot(xyRGB(1,:),xyRGB(2,:),'.')
axis equal;
axis tight
title('raw image');

subplot(2,3,3);
imshow(undistortImage);
hold on;
plot(xyzRGBnormal(1,:),xyzRGBnormal(2,:),'.')
axis equal;
axis tight
title('undistorted image');

subplot(2,3,4);
imagesc(undistortDepth);
axis equal; axis tight; axis off;
title('undistorted depth');

subplot(2,3,5);
imshow(undistortIR);
title('undistorted IR');

subplot(2,3,6);
imagesc(imageDepth);
axis equal; axis tight; axis off;
title('depth on undistorted image');
