function [sphereImg validMap] = imNormal2Sphere(im, imHoriFOV, sphereW, sphereH)

%{
Citation:
J. Xiao, K. A. Ehinger, A. Oliva and A. Torralba.
Recognizing Scene Viewpoint using Panoramic Place Representation.
Proceedings of 25th IEEE Conference on Computer Vision and Pattern Recognition, 2012.
http://sun360.mit.edu
%}

[TX TY] = meshgrid(1:sphereW, 1:sphereH);
TX = TX(:);
TY = TY(:);

ANGx = (TX- sphereW/2 -0.5)/sphereW * pi *2 ;
ANGy = -(TY- sphereH/2 -0.5)/sphereH * pi;

% clip ANGx
INDx = find(ANGx <= -pi/4);   ANGx(INDx) = -pi/4;
INDx = find(ANGx >=  pi/4);   ANGx(INDx) =  pi/4;


% convert angle to pixel of normal image

imW = size(im,2);   imH = size(im,1);
f = (imW/2) / tan(imHoriFOV/2);
Px = f * tan(ANGx);
d = sqrt(Px .^2 + f ^2);
Py = d .* tan(ANGy);
Px = Px + imW/2 + 1;
Py = -Py + imH/2 + 1; 

% outside range?
validMap = (Px<1  ) | (Px>imW) | (Py<1  ) | (Py>imH);
validMap = reshape(validMap, sphereH, sphereW);
validMap = ~validMap;

INDout = find(Px<1  );   Px(INDout) = 1;  Py(INDout) = 1;
INDout = find(Px>imW);   Px(INDout) = 1;  Py(INDout) = 1;
INDout = find(Py<1  );   Px(INDout) = 1;  Py(INDout) = 1;
INDout = find(Py>imH);   Px(INDout) = 1;  Py(INDout) = 1;


Px = reshape(Px, sphereH, sphereW);
Py = reshape(Py, sphereH, sphereW);

% finally warp image
sphereImg = warpImageFast(im, Px, Py);
