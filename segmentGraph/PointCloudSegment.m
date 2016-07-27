%%
load /Volumes/sun3d/robot_in_a_room/code/Annotation/all.mat
points2ply('pointSegAll.ply',XYZ_all,color_all);

colors = hsv(max(ptsSegIdx+1));
colors = colors(randperm(size(colors,1)),:);
colors(1,:) = [0 0 0];
colors = colors(ptsSegIdx+1,:)';
points2ply('pointPlanes.ply',XYZ_all,colors);

%%
XYZall = XYZ_all;
RGBall = double(color_all)/255;

fprintf('#vertices = %d\n',size(XYZall,2));

disp('neighbor searching...'); tic;
%[idx, dist] = rangesearch(XYZall',XYZall',0.10);
[idx, dist] = knnsearch(XYZall',XYZall','K',5);
toc;

if iscell(dist)
    neighborCnts = cellfun(@numel, dist);
    clf; hist(neighborCnts,0:max(neighborCnts));
    fprintf('#edges = %d\n',(sum(neighborCnts)-length(idx))/2);
end


Nnn = 5;
Nrange = 5;

edges = zeros(3,0);
disp('connecting edges...'); tic;
for vertex = 1:length(idx)
    if iscell(idx)
        idx_vertex = idx{vertex};
        dist_vertex= dist{vertex};
        
        if length(idx_vertex)>(Nnn+Nrange)
            selectors = [1:Nnn randperm(length(idx_vertex)-Nnn)+Nnn];
            selectors = selectors(1:(Nnn+Nrange));
            idx_vertex = idx_vertex(selectors);
            dist_vertex = dist_vertex(selectors);
        end
    else
        idx_vertex = idx(vertex,:);
        dist_vertex= dist(vertex,:);
    end
    neighbors = idx_vertex;
    selectors = neighbors>vertex;
    neighbors = neighbors(selectors);
    weights = dist_vertex(selectors);
    numNewEdges = length(neighbors);   
    edges = horzcat(edges, [repmat(vertex,1,numNewEdges); neighbors; weights]);
end
toc;


maxID = length(idx);
numEdges = size(edges,2);
fprintf('#edges = %d\n',numEdges);




% visualize graph
addpath /n/fs/vision/www/pvt
graph2ply('graph.ply', XYZall, edges(1:2,:), RGBall);


%load debug


save('debugHybrid.mat');

points2ply('pointsNormals.ply',XYZall,RGBall,normals);

%points2ply('pointsRGB.ply',XYZall,RGBall);


%%

load('debugHybrid.mat');
diffColor  = RGBall(:,edges(1,:)) - RGBall(:,edges(2,:));
diffColor  = sum(diffColor.^2,1)/3;
diffNormal = 1- abs(dot(normals(:,edges(1,:)), normals(:,edges(2,:))));
indxPlane  = ptsSegIdx(edges(1,:)) ~= ptsSegIdx(edges(2,:));

histColor  = hist(diffColor,0:0.01:1);
histNormal = hist(diffNormal,0:0.01:1);

%{
% visualize the difference distribution
figure
plot(histColor,'-r');
hold on;
plot(histNormal,'-b');
%}

edges(3,:) = 1 * diffColor + 50000 * double(indxPlane); % .* diffNormal; % .* 

%{
PValue = zeros(7,size(edges,2),2);

PValue(1:3,:,1) = RGBall(:,edges(1,:));

for e=1:size(edges,2)
    PValue(1:3,e,1) = RGBall(:,edges(1,e));
    PValue(4:6,e,1) = normals(:,edges(1,e));
    PValue(  7,e,1) = ptsSegIdx(edges(1,e));

    PValue(1:3,e,2) = RGBall(:,edges(2,e));
    PValue(4:6,e,2) = normals(:,edges(2,e));
    PValue(  7,e,2) = ptsSegIdx(edges(2,e));

    
    %{
    (4,e) = dot(), normals(:,edges(2,e)));
    (5,e) = ptsSegIdx(edges(1,e)) == ptsSegIdx(edges(2,e));
    
    % overwrite the edges by color
    if ptsSegIdx(edges(1,e)) == ptsSegIdx(edges(2,e))
        edges(3,e) =  ( norm( RGBall(:,edges(1,e)) - RGBall(:,edges(2,e)) ) );
    else
        edges(3,e) =  ( norm( RGBall(:,edges(1,e)) - RGBall(:,edges(2,e)) ) ) ...
        + (1- abs(dot(normals(:,edges(1,e)), normals(:,edges(2,e)))));
    end
    %}
    %edges(3,e) =  ( norm( RGBall(:,edges(1,e)) - RGBall(:,edges(2,e)) ) );
    %+ (1- abs(dot(normals(:,edges(1,e)), normals(:,edges(2,e)))));
end
%}

%{

RGBall(1,:)=1;
RGBall(2,:)=0;
RGBall(3,:)=0;

sel = XYZall(3,:)>0;

RGBall(1,sel)=0;
RGBall(2,sel)=1;
RGBall(3,sel)=0;

for e=1:size(RGBall,2)
    edges(3,e) = norm( RGBall(:,edges(1,e)+1) - RGBall(:,edges(2,e)+1) );
end

points2ply('pointsRGB.ply',XYZall,RGBall);
%}

%{
% visualize the graph
verticesToShow = [1:150692];
clf
plot3(XYZall(1,verticesToShow),XYZall(2,verticesToShow),XYZall(3,verticesToShow),'r.');
axis equal
hold on
for e = 1:size(edges,2)
    if any(verticesToShow==edges(1,e)) && any(verticesToShow==edges(2,e))
        plot3(XYZall(1,edges(1:2,e)'),XYZall(2,edges(1:2,e)'),XYZall(3,edges(1:2,e)'),'-');
    end
end
%}

%edges(3,:) = edges(3,:) * 10;

%% algorithm

%cd /Volumes/sun3d/robot_in_a_room/code/RGBDsfm_pano/segmentation
addpath /n/fs/vision/www/pvt/segmentGraph

%{
edges = [...
    0 2 0 1 0 1
    1 3 2 3 3 2
    0.1 0.1 1 1 1 1];
numVertices = 4;
numEdges = size(edges,2);


edges = [...
    0
    1
    1];
maxID = 2;
numEdges = size(edges,2);
%}

% prepare edges for calling the mex function
edges4mex = double(edges);
edges4mex(1,:) = edges4mex(1,:) - 1;
edges4mex(2,:) = edges4mex(2,:) - 1;
[~, idx] = sort(edges4mex(3,:));
edges4mex = edges4mex(:,idx);
edgeLabel = segmentGraph(size(XYZall,2), size(edges4mex,2), edges4mex, 50, 50);
% map the labels to 1:#labels
labels = unique(edgeLabel);
indMap(labels+1) = 1:length(labels);
edgeLabel = indMap(edgeLabel+1);
numLabels = max(edgeLabel);
fprintf('# of clusters = %d\n',numLabels);



% visualizaiton
%colors = hsv(numLabels);
%colors = colors(randperm(numLabels),:)';
colors = rand(3,numLabels);
points2ply('~/Downloads/segmentResult.ply',XYZall,colors(:,edgeLabel));


%% segment a frame

addpath(genpath('..'));

frameID = 1;
deviceID = 2;

IMGcam = readImage(dataArray{deviceID}.image{frameID});
if any(IMGcam(:)>1)
    IMGcam = IMGcam/255;
end
IMGcam = reshape(IMGcam,[],3)';


XYZcam = depth2XYZcamera(dataArray{deviceID}.K, depthRead(dataArray{deviceID}.depth{frameID}));
XYZcam = reshape(XYZcam,[],4)';
XYZcam(1:3,:) = XYZcam(1:3,:) * Calibration.Scale(deviceID);
XYZworld = transformRT(transformRT(XYZcam(1:3,:),Calibration.Rt{deviceID}), cameraRtC2Wrect(:,:,frameID));
% points2ply('~/Downloads/frameXYZworld.ply',XYZworld); % debug coordinates

selectors = boolean(XYZcam(4,:));
numIdx = 1:length(selectors);

numIdx = numIdx(selectors);
XYZworld = XYZworld(:,selectors);

[idx, dist] = knnsearch(XYZall',XYZworld','K',1);

foundNN = dist < 0.2;
idx = idx(foundNN);
dist= dist(foundNN);
numIdx = numIdx(foundNN);

segMask = nan(480,640);
segMask(numIdx) = edgeLabel(idx);
segMask(isnan(segMask(:))) = numLabels+1;
colors(:,numLabels+1) = [0;0;0];

visMask = reshape(colors(:,segMask(:))',[480 640 3]);

imwrite(visMask,'~/Downloads/segmentResult.png');

