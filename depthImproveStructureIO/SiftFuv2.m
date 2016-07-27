function depthRefined = SiftFuv2(sequenceName,frameIDtarget, interval)

%try    
%    load('debug.mat');
%catch

    if ~exist('sequenceName','var')
        sequenceName = '2014_04_02-14_13_45';
    end

    if ~exist('frameIDtarget','var')
        frameIDtarget = 11;
    end

    if ~exist('interval','var')
        interval = 10;
    end

    data = loadSUN3Dv2(sequenceName);

    frameIDs = max(frameIDtarget-interval,1):min(data.image.NumberOfFrames,frameIDtarget+interval);

    frames = getRGBDframe(data,frameIDs);

    Rts = repmat([eye(3) zeros(3,1)],[1,1,length(frameIDs)]);

    itarget = find(frameIDs==frameIDtarget);

    for i = 1:length(frameIDs)
        if i~=itarget
            fprintf('matching frame %d and frame %d\n',frameIDs(itarget),frameIDs(i));
            Rts(:,:,i) = align2RGBD(frames(:,:,:,itarget), frames(:,:,:,i));
        end
    end

    %depthRefined=[]; save('debug.mat','Rts');
%end


voxel.unit = 0.01; %0.01; % Kevin: 4mm = 0.004 meter. Kinect cannot go better than 3mm
voxel.mu_grid = 5; % used to be 4
voxel.size_grid = [512; 512; 512]; %[512; 512; 1024]; % [512; 512; 512];

voxel.range(1,1) = - voxel.size_grid(1) * voxel.unit / 2;
voxel.range(1,2) = voxel.range(1,1) + (voxel.size_grid(1)-1) * voxel.unit;

voxel.range(2,1) = - voxel.size_grid(2) * voxel.unit / 2;
voxel.range(2,2) = voxel.range(2,1) + (voxel.size_grid(2)-1) * voxel.unit;

voxel.range(3,1) = 0.4; % - voxel.size_grid(3) * voxel.unit / 2;
voxel.range(3,2) = voxel.range(3,1) + (voxel.size_grid(3)-1) * voxel.unit;

voxel.mu = voxel.mu_grid * voxel.unit;

fprintf('memory = %f GB\n',  prod(voxel.size_grid) * 4 / (1024*1024*1024));
fprintf('space = %.2f m x %.2f m x %.2f m ', voxel.size_grid(1) * voxel.unit, voxel.size_grid(2) * voxel.unit, voxel.size_grid(3) * voxel.unit);
fprintf('= [%.2f,%.2f] x [%.2f,%.2f] x [%.2f,%.2f]\n',voxel.range(1,1),voxel.range(1,2),voxel.range(2,1),voxel.range(2,2),voxel.range(3,1),voxel.range(3,2));

tsdf_value  =  ones([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');
tsdf_weight = zeros([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');


% get the grid there
disp('meshgrid');
tic;
[X,Y,Z]=ndgrid(1:voxel.size_grid(1),1:voxel.size_grid(2),1:voxel.size_grid(3));
toc;
disp('grid to world');
tic;
X = X(:)'; Y = Y(:)'; Z = Z(:)';
gridIndexAll = sub2ind(voxel.size_grid',X,Y,Z);
gridCoordinateW = [single(X)*voxel.unit + voxel.range(1,1); single(Y)*voxel.unit + voxel.range(2,1); single(Z)*voxel.unit + voxel.range(3,1)];
clear X Y Z;
toc;

dispclim = [0 8];

for i=1:length(frameIDs)
    
    frameID=frameIDs(i);

    
    depth = get_depth(imread(data.depth{frameID}));

    if i==itarget
        figure;imagesc(depth,dispclim); axis equal; axis tight; axis off; title('raw depth');
    end
    
    
    % transform the grid
    disp('transform');
    tic;
    gridCoordinateC = transformPointCloud(gridCoordinateW, Rts(:,:,i));
    toc;

    % select: in front of camera
    disp('select: in front of camera');
    tic;
    isValid = find(gridCoordinateC(3,:)>0);
    gridCoordinateC = gridCoordinateC(:,isValid);
    gridIndex = gridIndexAll(isValid);
    toc;

    % select: project 
    disp('select: project');
    
    
    
    
    tic;
    pxy = round(1+project_points2(gridCoordinateC,data.camera.D.fc,data.camera.D.cc,data.camera.D.kc,data.camera.D.alpha_c));    

    isValid = (1<=pxy(1,:) & pxy(1,:) <= data.camera.D.width & 1<=pxy(2,:) & pxy(2,:)<= data.camera.D.height);
    gridCoordinateC = gridCoordinateC(:,isValid);
    gridIndex = gridIndex(isValid);
    py = pxy(2,isValid);
    px = pxy(1,isValid);
    toc;

    % select: valid depth
    disp('select: valid depth');
    tic;
    ind = sub2ind([data.camera.D.height data.camera.D.width],py,px);
    isValid = depth(ind)~=0;
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
    eta = (depth(ind)- gridCoordinateC(3,:)) .* ((1+ (gridCoordinateC(1,:)./gridCoordinateC(3,:)).^2 + (gridCoordinateC(2,:)./gridCoordinateC(3,:)).^2 ).^0.5);
    toc;

    %tic;
    %XYZmeasure = [XYZcam(ind);XYZcam(ind+640*480);XYZcam(ind+640*480*2)];
    %Dmeasure = sqrt(sum(XYZmeasure.^2,1));
    %Dtran    = sqrt(sum(gridCoordinateC.^2,1));
    %eta = Dmeasure-Dtran;
    %toc;

    % select: > - mu
    disp('select: > - mu');
    tic;
    isValid = eta>-voxel.mu;
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

    
end


[pX,pY]=meshgrid(0:data.camera.D.width-1,0:data.camera.D.height-1);

raycastingDirectionW = [pX(:)'-data.camera.D.KK(1,3); pY(:)'-data.camera.D.KK(2,3); mean([data.camera.D.KK(1,1) data.camera.D.KK(2,2)])*ones(1,data.camera.D.width*data.camera.D.height)]; % clipping at 8 meter is the furthest depth of kinect
raycastingDirectionW = raycastingDirectionW ./ repmat(sqrt(sum(raycastingDirectionW.^2,1)),3,1);

num_directions = size(raycastingDirectionW,2);

camCenterW = [0;0;0];

castingRange = [0.4 8];

raycastingDirectionWinv = raycastingDirectionW.^-1;
tt = sort(cat(3, repmat(voxel.range(:,1) + repmat(voxel.unit,3,1) - camCenterW,1,num_directions), repmat(voxel.range(:,2) - repmat(voxel.unit,3,1) - camCenterW,1,num_directions)) .* repmat(raycastingDirectionWinv,[1,1,2]),3);
tnearArray =  max(max(tt(:,:,1),[],1), castingRange(1));
tfarArray =  min(min(tt(:,:,2),[],1), castingRange(2));


camCenterWgrid = (camCenterW - voxel.range(:,1)) / voxel.unit + 1;


step = voxel.unit;
largestep = 0.75 * voxel.mu;

%tPrev = 0;

tMap = single(NaN(1,data.camera.D.width*data.camera.D.height));
raycast(tMap, single(raycastingDirectionW/voxel.unit), single(tnearArray), single(tfarArray), single(camCenterWgrid-1), tsdf_value, size(tsdf_value,1), size(tsdf_value,2),step, largestep);


% computer vertex map
VMap = repmat(camCenterW,1,data.camera.D.width*data.camera.D.height) + raycastingDirectionW .* (repmat(tMap,3,1));


depthRefined = reshape(VMap(3,:),data.camera.D.height,data.camera.D.width);

figure;imagesc(depthRefined,dispclim); axis equal; axis tight; axis off; title('refined depth');


% 
[x,y] = meshgrid(0:data.camera.D.width-1, 0:data.camera.D.height-1);
X(1,:) = reshape((x-data.camera.D.KK(1,3)).*depthRefined/data.camera.D.KK(1,1),1,[]);
X(2,:) = reshape((y-data.camera.D.KK(2,3)).*depthRefined/data.camera.D.KK(2,2),1,[]);
X(3,:) = reshape(depthRefined,1,[]);
X = X(:,~isnan(depthRefined(:)));

points2ply('pt_Mac.ply', X);

    