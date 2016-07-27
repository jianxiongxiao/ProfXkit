function updateTSDF(camRtC2W)

global ViewFrustumC;
ViewFrustumW = transformRT(ViewFrustumC, camRtC2W);

range2test = [min(ViewFrustumW, [], 2) max(ViewFrustumW, [], 2)];

global XYZcam;
global voxel;
global K;
global tsdf_value;
global tsdf_weight;

% choose a bounding box to contain viewing frustum
rangeGrid = (range2test - voxel.range(:,[1 1])) / voxel.unit + 1;
rangeGrid(:,1) = max(1,floor(rangeGrid(:,1)));
rangeGrid(:,2) = min(ceil (rangeGrid(:,2)),voxel.size_grid);

% get the grid there
disp('meshgrid');
tic;
[Y,X,Z]=meshgrid(rangeGrid(1,1):rangeGrid(1,2),rangeGrid(2,1):rangeGrid(2,2),rangeGrid(3,1):rangeGrid(3,2)); % strange matlab syntax
toc;
disp('grid to world');
tic;
X = X(:)'; Y = Y(:)'; Z = Z(:)';
gridIndex = sub2ind(voxel.size_grid',X,Y,Z);
gridCoordinateW = [single(X)*voxel.unit + voxel.range(1,1); single(Y)*voxel.unit + voxel.range(2,1); single(Z)*voxel.unit + voxel.range(3,1)];
clear X Y Z;
toc;

% transform the grid
disp('transform');
tic;
gridCoordinateC = transformRT(gridCoordinateW, camRtC2W, true);
toc;

% select: in front of camera
disp('select: in front of camera');
tic;
isValid = find(gridCoordinateC(3,:)>0);
gridCoordinateC = gridCoordinateC(:,isValid);
gridIndex = gridIndex(isValid);
toc;

% select: project 
disp('select: project');
tic;
px = round(K(1,1)*(gridCoordinateC(1,:)./gridCoordinateC(3,:)) + K(1,3));
py = round(K(2,2)*(gridCoordinateC(2,:)./gridCoordinateC(3,:)) + K(2,3));
isValid = (1<=px & px <= 640 & 1<=py & py<= 480);
gridCoordinateC = gridCoordinateC(:,isValid);
gridIndex = gridIndex(isValid);
py = py(isValid);
px = px(isValid);
toc;

% select: valid depth
disp('select: valid depth');
tic;
ind = sub2ind([480 640],py,px);
isValid = XYZcam(ind+640*480*3)~=0;
gridCoordinateC = gridCoordinateC(:,isValid);
gridIndex = gridIndex(isValid);
ind = ind(isValid);
toc;

% compare distance between measurement and the grid
disp('compare distance between measurement and the grid');
tic;
XYZmeasure = [XYZcam(ind);XYZcam(ind+640*480);XYZcam(ind+640*480*2)];
Dmeasure = sqrt(sum(XYZmeasure.^2,1));
Dtran    = sqrt(sum(gridCoordinateC.^2,1));
eta = Dmeasure-Dtran;
toc;

% select: > - mu
disp('select: > - mu');
tic;
isValid = eta>=-voxel.mu;
eta = eta(isValid);
gridIndex = gridIndex(isValid);
ind = ind(isValid);
new_value = min(1,eta/voxel.mu);
toc;

disp('read write tsdf');
tic;
old_weight = tsdf_weight(gridIndex); 
new_weight = old_weight + 1;   
tsdf_weight (gridIndex)= new_weight;
tsdf_value (gridIndex) = (tsdf_value(gridIndex).*old_weight +new_value)./new_weight;
toc;

disp('coloring');
tic;
global tsdf_color;
global IMGcam;
if ~isempty(tsdf_color)
    isValid = eta<=voxel.mu;
    eta = eta(isValid);
    gridIndex = gridIndex(isValid);
    ind = ind(isValid);
    
    IMGmeasure = [IMGcam(ind);IMGcam(ind+640*480);IMGcam(ind+640*480*2)];
    
    colorArray = reshape(typecast(tsdf_color(gridIndex),'uint8'),4,[]);
    
    
    old_weight = colorArray(4,:);
    old_weight(double(old_weight)>=255) = 254;        
    new_weight = old_weight + 1;   
    
    newArray = uint8(round((double(colorArray(1:3,:)) .* repmat(double(old_weight),3,1) + double(IMGmeasure)) ./ repmat(double(new_weight),3,1)));
    newArray(4,:) = new_weight;
    
    tsdf_color(gridIndex) = typecast(newArray(:),'uint32');
end
toc;



