function [XYZworld, faces, tsdf_value, tsdf_weight] = TSDFmesh(data, frameIdtarget,frameIds,cameraRtC2W)


cameraRtC2Wframes = cameraRtC2W(:,:,frameIds);
frameIdtargetID = find(frameIds==frameIdtarget);

mapRt = transformCameraRt(cameraRtC2Wframes(:,:,frameIdtargetID));

for i=1:length(frameIds)
    cameraRtC2Wframes(:,:,i) = concatenateRts(mapRt, cameraRtC2Wframes(:,:,i));
end

%% tsdf


voxel.unit = 0.01; % Kevin: 4mm = 0.004 meter. Kinect cannot go better than 3mm
voxel.mu_grid = 10; % used to be 4
voxel.size_grid = [512; 512; 1024]; % [512; 512; 512];

voxel.range(1,1) = - voxel.size_grid(1) * voxel.unit / 2;
voxel.range(1,2) = voxel.range(1,1) + (voxel.size_grid(1)-1) * voxel.unit;

voxel.range(2,1) = - voxel.size_grid(2) * voxel.unit / 2;
voxel.range(2,2) = voxel.range(2,1) + (voxel.size_grid(2)-1) * voxel.unit;

voxel.range(3,1) = -0.5; % - voxel.size_grid(3) * voxel.unit / 2;
voxel.range(3,2) = voxel.range(3,1) + (voxel.size_grid(3)-1) * voxel.unit;

voxel.mu = voxel.mu_grid * voxel.unit;

fprintf('memory = %f GB\n',  prod(voxel.size_grid) * 4 / (1024*1024*1024));
fprintf('space = %.2f m x %.2f m x %.2f m ', voxel.size_grid(1) * voxel.unit, voxel.size_grid(2) * voxel.unit, voxel.size_grid(3) * voxel.unit);
fprintf('= [%.2f,%.2f] x [%.2f,%.2f] x [%.2f,%.2f]\n',voxel.range(1,1),voxel.range(1,2),voxel.range(2,1),voxel.range(2,2),voxel.range(3,1),voxel.range(3,2));


%tsdf_value  = -ones([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');
tsdf_value  =  ones([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');
tsdf_weight = zeros([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');


f = data.K(1,1);

ViewFrustumC = [...
    0 -data.K(1,3) -data.K(1,3)  data.K(1,3)  data.K(1,3);
    0 -data.K(2,3)  data.K(2,3)  data.K(2,3) -data.K(2,3);
    0    f    f    f    f];
ViewFrustumC = ViewFrustumC/f * 8; % 8 meter is the furthest depth of kinect

% precompute
[pX,pY]=meshgrid(1:640,1:480);

raycastingDirectionC = [pX(:)'-data.K(1,3); pY(:)'-data.K(2,3); f*ones(1,640*480)]; % clipping at 8 meter is the furthest depth of kinect
raycastingDirectionC = raycastingDirectionC ./ repmat(sqrt(sum(raycastingDirectionC.^2,1)),3,1);

%% get the grid there

%underConsideration = true(1,prod(voxel.size_grid));

%% speed up by eliminate free space

% if you want to debug fast, enough some frames only
% for i=1:33:length(frameIds) 
for i=1:length(frameIds) 
    
    fprintf('======================================== frame %d ========================================\n',i);
    
    camRtC2W = cameraRtC2Wframes(:,:,i);
    
    XYZcam = depth2XYZcamera(data.K, depthRead(data.depth{frameIds(i)}));
    
    ViewFrustumW = transformRT(ViewFrustumC, camRtC2W);

    range2test = [min(ViewFrustumW, [], 2) max(ViewFrustumW, [], 2)];

    % choose a bounding box to contain viewing frustum
    rangeGrid = (range2test - voxel.range(:,[1 1])) / voxel.unit + 1;
    rangeGrid(:,1) = max(1,floor(rangeGrid(:,1)));
    rangeGrid(:,2) = min(ceil (rangeGrid(:,2)),voxel.size_grid);
    rangeGrid = int32(rangeGrid);

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
    
    % 
    %underConsiderationHere = underConsideration(gridIndex);
    %gridCoordinateW = gridCoordinateW(:,underConsiderationHere);
    %gridIndex = gridIndex(underConsiderationHere);

    
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
    px = round(data.K(1,1)*(gridCoordinateC(1,:)./gridCoordinateC(3,:)) + data.K(1,3));
    py = round(data.K(2,2)*(gridCoordinateC(2,:)./gridCoordinateC(3,:)) + data.K(2,3));
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
    %{

            const float diff = (depth[px] - cameraX.z) * sqrt(1+sq(pos.x/pos.z) + sq(pos.y/pos.z));
            if(diff > -mu){
                const float sdf = fminf(1.f, diff/mu);
                float2 data = vol[pix];
                data.x = clamp((data.y*data.x + sdf)/(data.y + 1), -1.f, 1.f);
                data.y = fminf(data.y+1, maxweight);
                vol.set(pix, data);
            }

    %}
    tic;
    eta = (XYZcam(ind+640*480*2)- gridCoordinateC(3,:)) .* ((1+ (gridCoordinateC(1,:)./gridCoordinateC(3,:)).^2 + (gridCoordinateC(2,:)./gridCoordinateC(3,:)).^2 ).^0.5);
    toc;

    %tic;
    %XYZmeasure = [XYZcam(ind);XYZcam(ind+640*480);XYZcam(ind+640*480*2)];
    %Dmeasure = sqrt(sum(XYZmeasure.^2,1));
    %Dtran    = sqrt(sum(gridCoordinateC.^2,1));
    %eta = Dmeasure-Dtran;
    %toc;

    % 
    %disp('speed up');
    %isValid = eta>voxel.mu*2;
    %underConsideration(gridIndex(isValid)) = false;
    
    
    % select: > - mu
    disp('select: > - mu');
    tic;
    isValid = eta>-voxel.mu;
    eta = eta(isValid);
    gridIndex = gridIndex(isValid);
    ind = ind(isValid);
    toc;
    
    
    new_value = min(1,eta/voxel.mu);

    
    disp('read write tsdf');
    tic;
    old_weight = tsdf_weight(gridIndex); 
    new_weight = old_weight + 1;   
    tsdf_weight (gridIndex)= new_weight;
    tsdf_value (gridIndex) = (tsdf_value(gridIndex).*old_weight +new_value)./new_weight;
    toc;
    
    % visualizing the voxel
    %{
    figure(1)
    min_weight = min(tsdf_weight(:));
    max_weight = max(tsdf_weight(:));
    for ii=1:voxel.size_grid(3)
        if min(min(min(tsdf_value(:,:,ii)))) ~= max(max(max(tsdf_value(:,:,ii))))
            imagesc(tsdf_weight(:,:,ii)',[min_weight max_weight]); axis equal; axis tight; xlabel('x'); ylabel('y');
            title(['frame ' num2str(ii) ' = depth ' num2str((ii-1)*voxel.unit+voxel.range(3,1)) ' meter']);
            pause(0.05);
        end
    end

    figure(2)
    for ii=1:voxel.size_grid(3)
        if min(min(min(tsdf_value(:,:,ii)))) ~= max(max(max(tsdf_value(:,:,ii))))
            imagesc(tsdf_value(:,:,ii)',[-1 1]); axis equal; axis tight; xlabel('x'); ylabel('y');
            title(['frame ' num2str(ii) ' = depth ' num2str((ii-1)*voxel.unit+voxel.range(3,1)) ' meter']);
            pause(0.05);
        end
    end    
    %}
end

%% meshing
disp('isosurfacing...');
tic;
fv = isosurface(tsdf_value,0);
toc;
% visualizaiton
%{
figure(3);
p = patch(fv);
p.FaceColor = 'red';
p.EdgeColor = 'none';
daspect([1,1,1])
view(3); axis tight
camlight 
lighting gouraud
%}

%% remove bad points that are artifact of TSDF

XYZ = fv.vertices';

faces = fv.faces';

XYZ = XYZ([2 1 3],:);


XYZint = round(XYZ);


selected = 1< XYZint(1,:) & XYZint(1,:) < voxel.size_grid(1) & 1< XYZint(2,:) & XYZint(2,:) < voxel.size_grid(2) & 1< XYZint(3,:) & XYZint(3,:) < voxel.size_grid(3);
XYZint = XYZint(:,selected);
XYZ = XYZ(:,selected);
faces = faces(:,selected(faces(1,:)) & selected(faces(2,:)) & selected(faces(3,:)));
indNew = cumsum(double(selected));
faces = indNew(faces);

gridIndex = sub2ind(voxel.size_grid',XYZint(1,:),XYZint(2,:),XYZint(3,:));
valIndex = tsdf_value(gridIndex);
selected = -0.15 < valIndex & valIndex<0.15;
XYZint = XYZint(:,selected);
XYZ = XYZ(:,selected);
faces = faces(:,selected(faces(1,:)) & selected(faces(2,:)) & selected(faces(3,:)));
indNew = cumsum(double(selected));
faces = indNew(faces);
 

XYZworld = (XYZ-1) *  voxel.unit + repmat(voxel.range(:,1),1,size(XYZ,2));

%XYZworld = XYZworld([2 1 3],:);



% visualizaiton

figure(4)
clf;
plot3(XYZworld(1,:),XYZworld(2,:),XYZworld(3,:),'.r');
XYZcam = depth2XYZcamera(data.K, depthRead(data.depth{frameIdtarget}));
XYZcam = reshape(XYZcam,[],4)';
XYZcam = XYZcam(:,XYZcam(4,:)~=0);
XYZcam = XYZcam(1:3,:);
hold on
plot3(XYZcam(1,:),XYZcam(2,:),XYZcam(3,:),'.b');
axis equal;
axis tight;
grid on;
xlabel('x');
ylabel('y');
zlabel('z');


figure(5);
clf
fvNew.vertices = XYZworld';
fvNew.faces = faces';
%fvNew.faces = fvNew.faces(randsample(size(fvNew.faces,1),10000),:);
p = patch(fvNew,'FaceColor','none','EdgeColor','red');
daspect([1,1,1])
view(3); axis tight






