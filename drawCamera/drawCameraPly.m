function drawCameraPly(PLYfilename,Rt,scale,w,h,f)

if ~exist('w','var')
    w = 640;
end
if ~exist('h','var')
    h = 480;
end
if ~exist('f','var')
    f = 570.3422090067766703214147128164768218994140625;
end
if ~exist('scale','var')
    scale = 0.01;
end

camera=[...
0 -w/2 +w/2 +w/2 -w/2
0 -h/2 -h/2 +h/2 +h/2
0   f    f    f    f];

camera = camera * scale;
camera = Rt(:,1:3) * camera + repmat(Rt(:,4),1,5);
edges = [1 2; 1 3; 1 4; 1 5; 2 3;3 4;4 5;5 2]';


graph2ply(PLYfilename, camera, edges);

%{
plot3(camera(1,[2 3 4 5 2]),camera(2,[2 3 4 5 2]),camera(3,[2 3 4 5 2]),'-k'); hold on;
for i=2:5
    plot3(camera(1,[1 i]),camera(2,[1 i]),camera(3,[1 i]),'-k'); hold on;
end
axis equal
xlabel('x');
ylabel('y');
zlabel('z');
%}