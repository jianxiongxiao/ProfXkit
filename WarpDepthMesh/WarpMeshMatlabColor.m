function [label,depth] = WarpMeshMatlabColor(XYZcamera,labelNow,K, Rt)

%mex WarpMesh.cpp -lGLU -lOSMesa
%load debug.mat

XYZcamera = double(XYZcamera);

%XYZcamera(:,:,4) = XYZcamera(:,:,4) .* double(labelNow);

good = XYZcamera(:,:,4)~=0;
good = good(:);

X = reshape(XYZcamera,[],4)';
X = X(1:3,:);
X = transformPointCloud(X,Rt);
X = reshape(X',[480,640,3]);
XYZcamera(:,:,1) = X(:,:,1);
XYZcamera(:,:,2) = X(:,:,2);
XYZcamera(:,:,3) = X(:,:,3) .* double(XYZcamera(:,:,4)~=0);


P = [K [0;0;0]];
XYZcamera(:,:,1) = -XYZcamera(:,:,1);

%{
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
%}
labelNow = double(labelNow);
XYZcamera(:,:,4) = labelNow(:,:,1) + labelNow(:,:,2) * 256  + labelNow(:,:,3) * 256 * 256;

[label,depth]=WarpMeshColor(P,640,480,XYZcamera);




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

R = mod(label,256);
G = mod(floor(label/256),256);
B = floor(label/(256*256));

label(:,:,1) = R;
label(:,:,2) = G;
label(:,:,3) = B;


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
