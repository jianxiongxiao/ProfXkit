function [label,depth] = RenderPCcameraMatlab(XYZ,RGB,XYZedges,RGBedges,K, Rt,width, height)

% XYZ should be 3*N double
% RGB should be 3*N uint8

%mex WarpMesh.cpp -lGLU -lOSMesa
%load debug.mat

if ~isempty(XYZ)
    XYZ = double(XYZ);
    XYZ = transformPointCloud(XYZ,Rt);
    XYZ(1,:) = -XYZ(1,:);
end

if ~isempty(XYZedges)
    XYZedges = double(XYZedges);
    XYZedges = transformPointCloud(XYZedges,Rt);
    XYZedges(1,:) = -XYZedges(1,:);
end

%{
figure(5); clf;
plot3(X(1,:),X(2,:),X(3,:),'.');
axis equal;
grid on;
xlabel('x');
ylabel('y');
zlabel('z');
set(gca,'ZDir','reverse');
set(gca,'YDir','reverse');
%}
P = [K [0;0;0]];
[label,depth]=RenderPCcamera(P,width,height,XYZ,RGB,XYZedges,RGBedges);

%{



% to deal with camera coodinate system
%XYZcamera(:,:,1) = -XYZcamera(:,:,1);
%P = K * Rt;
%P = P * [-1 0 0 0; 0 1 0 0; 0 0 1 0; 0 0 0 1];

%P = Rt;

XYZcamera(:,:,2) = -XYZcamera(:,:,2);
XYZcamera(:,:,3) = -XYZcamera(:,:,3);

F = [1 0 0 ; 0 -1 0; 0 0 -1];

P = [ F*Rt(:,1:3)*inv(F) F*Rt(:,4)];
%P = Rt; % * [1 0 0 0; 0 -1 0 0; 0 0 -1 0; 0 0 0 1];




%{
XYZcamera(:,:,2) = -XYZcamera(:,:,2);
XYZcamera(:,:,3) = -XYZcamera(:,:,3);
P = [1 0 0 0; 0 -1 0 0; 0 0 -1 0; 0 0 0 1] * [Rt; 0 0 0 1] * [1 0 0 0; 0 -1 0 0; 0 0 -1 0; 0 0 0 1];
P = P(1:3,:);
%}

good = XYZcamera(:,:,4)~=0;
good = good(:);

X = reshape(XYZcamera,[],4)';
X = X(1:3,good);

figure(5); clf;
plot3(X(1,:),X(2,:),X(3,:),'.');
axis equal;
grid on;
xlabel('x');
ylabel('y');
zlabel('z');
set(gca,'ZDir','reverse');
set(gca,'YDir','reverse');

X = transformPointCloud(X,P);


figure(3);clf;
plot3(X(1,:),X(2,:),X(3,:),'.');
axis equal;
grid on;
xlabel('x');
ylabel('y');
zlabel('z');
set(gca,'ZDir','reverse');
set(gca,'YDir','reverse');

figure(4);clf;
x= K*X;
x = [x(1,:)./x(3,:); x(2,:)./x(3,:)];
plot(x(1,:),x(2,:),'.')
axis equal
set(gca,'YDir','reverse');
hold on;
plot([1 640 640 1 1],[1 1 480 480 1],'-r');


P = K * P;

%{
XYZcamera(:,:,2) = -XYZcamera(:,:,2);
XYZcamera(:,:,3) = -XYZcamera(:,:,3);
%P = P * [1 0 0 0; 0 -1 0 0; 0 0 -1 0; 0 0 0 1];
Rt(2,4) = -Rt(2,4);
Rt(3,4) = -Rt(3,4);
P = K * Rt;
%}

[label,depth]=WarpMesh(P,640,480,XYZcamera);

%}

label = label';
label = label(:,end:-1:1);
%figure
%imagesc(label)

label = double(label);

B = mod(label,256);
G = mod(floor(label/256),256);
R = floor(label/(256*256));

clear label;
label(:,:,1) = R;
label(:,:,2) = G;
label(:,:,3) = B;
label = uint8(label);

depth = depth';
depth = depth(end:-1:1,end:-1:1);

if ~any(label(:))
    depth = single(zeros(size(depth)));
    return
end


z_near = 0.3;
z_far_ratio = 1.2;
depth = z_near./(1-single(depth)/2^32);
maxDepth = max(depth(abs(depth) < 100));

cropmask = (depth < z_near) | (depth > z_far_ratio * maxDepth);
depth(cropmask) = 0; %NaN;%z_far_ratio * maxDepth;


%figure
%imagesc(depth)
