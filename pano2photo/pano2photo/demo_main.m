%{
This code is to demonstrate how to generate a crop from a full view panorama 
into a normal image, and how to warp it back.
--jianxiong

Citation:
J. Xiao, K. A. Ehinger, A. Oliva and A. Torralba.
Recognizing Scene Viewpoint using Panoramic Place Representation.
Proceedings of 25th IEEE Conference on Computer Vision and Pattern Recognition, 2012.
http://sun360.mit.edu
%}


clear
clc

% parameters
new_imgH = 640;                 % horizontal resolution = width
new_imgShort = new_imgH/4*3;    % vertical resolution = height
fov = pi * 65.5 / 180;          % horizontal angle of view

% where is your center of the camera
% horizontal angle
x = - pi * 0.5;           % range [-pi,   pi]
% vertical angle
y = 0;                    % range [-pi/2, pi/2]


% read the panorama
panorama = imread('pano_aclzqydjlssfry.jpg');
panorama = double(panorama);

% generate the crop
warped_image = imgLookAt(panorama, x, y, new_imgH, fov );
warped_image = warped_image/255;
warped_image = warped_image((new_imgH-new_imgShort)/2+(1:new_imgShort),:,:);

% warp the crop back to panorama
% this function assume y==0. It won't work when y!=0, and you need to
% modify it.
[sphereImg validMap] = imNormal2Sphere(warped_image, fov, 1024, 512);
% fill in back for invalid area
sphereImg = sphereImg .* double(repmat(validMap,[1,1,3]));

subplot(3,1,1);
imshow(panorama/255);
title('full view panorama (360degree x 180degree)');

subplot(3,1,2);
imshow(warped_image);
title('generated crop');

subplot(3,1,3);
imshow(sphereImg);
title('warp the image back to panorama');
