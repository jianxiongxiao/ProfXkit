function [label,depth] = WarpDepthMatlab(XYZcamera,K, Rt, outputWidth, outputHeight, labelNow)

%mex WarpDepth.cpp -lGLU -lOSMesa

% mex WarpDepth.cpp  -L/opt/X11/lib/  -lOSMesa  -I/opt/X11/include/ /usr/local/Matlab/R2013a/sys/opengl/lib/glnxa64/libGL.so.1

%mex WarpDepth.cpp -lGLU -lOSMesa -I/opt/X11/include/ -L/opt/X11/lib/
%load debug.mat

XYZcamera = double(XYZcamera);

if exist('labelNow','var')
    XYZcamera(:,:,4) = XYZcamera(:,:,4) .* double(labelNow);
end

X = reshape(XYZcamera,[],4)';
X = X(1:3,:);
X = transformPointCloud(X,Rt);
X = reshape(X',[size(XYZcamera,1),size(XYZcamera,2),3]);
XYZcamera(:,:,1) = X(:,:,1);
XYZcamera(:,:,2) = X(:,:,2);
XYZcamera(:,:,3) = X(:,:,3);


P = [K [0;0;0]];
XYZcamera(:,:,1) = -XYZcamera(:,:,1);

[label,depth]=WarpDepth(P,outputWidth,outputHeight,double(XYZcamera),0.1);

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