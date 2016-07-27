%{
This code demonstrates how to warp a depth map (togeter with a label map) from a camera to another view.
It create a mesh using the depth map from a camera and render the mesh in OpenGL.
Therefore, it will not create artifacts with a lot of gaps in a warpped result.

compile
   mex WarpMesh.cpp -lGLU -lOSMesa
   you need to install osmesa to compile it
   in Mac OS X 10.9.2, you just need to install X11 on mac (xquartz) comes with mesa
   mex WarpMesh.cpp -lGLU -lOSMesa -I/opt/X11/include/ -L/opt/X11/lib/

Email Jianxiong if you have questions. Cite the following paper if you use this code:

J. Xiao, A. Owens and A. Torralba
SUN3D: A Database of Big Spaces Reconstructed using SfM and Object Labels
Proceedings of 14th IEEE International Conference on Computer Vision (ICCV2013)

%}

close all;
clear


load demo.mat

[label,depth] = WarpMeshMatlab(XYZcamera,labelNow,K, Rt);

% warp color
[imageWarp,depth] = WarpMeshMatlabColor(XYZcamera,double(image),K, Rt);


figure
subplot(2,3,1);
imagesc(XYZcamera(:,:,3));
axis equal; axis tight; axis off; title('before warping');

subplot(2,3,2);
imagesc(labelNow);
axis equal; axis tight; axis off; title('before warping');


subplot(2,3,4);
imagesc(depth);
axis equal; axis tight; axis off; title('after warping');

subplot(2,3,5);
imagesc(label);
axis equal; axis tight; axis off; title('after warping');


subplot(2,3,3);
imagesc(image);
axis equal; axis tight; axis off; title('before warping');

subplot(2,3,6);
imagesc(imageWarp/255);
axis equal; axis tight; axis off; title('after warping');



