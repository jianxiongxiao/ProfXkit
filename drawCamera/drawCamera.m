function drawCamera()

close all

addpath ../icosahedron2sphere

points = icosahedron2sphere(1);

points = points(points(:,3)>=0,:);

%{
plot3(points(:,1),points(:,2),points(:,3),'.')
title(sprintf('Level %d with %d points',1,size(points,1)))
axis equal
axis tight
xlabel('x');
ylabel('y');
zlabel('z');
%}

aspect_ratio = 4/3;
focal_length = 0.12;
h_fov = 54.4/180*pi;

w = tan(h_fov/2)*focal_length;
h = w/aspect_ratio;

camera=[...
0 -w           +w            +w            -w
0 -h           -h            +h            +h
0 focal_length focal_length  focal_length  focal_length];

%plotCamera(camera);

for i=1:size(points,1)
    center_ray = -points(i,:);
    
    projLen = sqrt(center_ray(1)^2+center_ray(2)^2);
    
    height = -projLen^2 / center_ray(3);
    
    upVector = [center_ray(1) center_ray(2) height];
    
    upVector = upVector /norm(upVector);
    
    %sinTheta = center_ray(3);
    
    leftVector = cross(center_ray,upVector);
    leftVector = leftVector/norm(leftVector);
    
    R = [leftVector' upVector' center_ray'];
    
    currentCamera = R * camera + repmat(points(i,:)',1,5);
   
    plotCamera(currentCamera);
end


axis equal
axis([-1 1 -1 1 -1 1]);
xlabel('x');
ylabel('y');
zlabel('z');

function plotCamera(camera)

%mid_ray = 1;
%side_rays = 1.2;

% frame
plot3(camera(1,[2 3 4 5 2]),camera(2,[2 3 4 5 2]),camera(3,[2 3 4 5 2]),'-k'); hold on;

% side rays
for i=2:5
    plot3(camera(1,[1 i]),camera(2,[1 i]),camera(3,[1 i]),'-k'); hold on;
end

