function [XYZworld,faces, RGBcolor, tsdf_value, tsdf_weight, tsdf_color] = TSDFmeshParallel(data, frameIdtarget,frameIds,cameraRtC2W, is_color, is_mesh)

if ~exist('is_color','var')
    is_color = true;
end

if ~exist('is_mesh','var')
    is_mesh = true;
end


N = matlabpool('size');
fprintf('%d threads\n',N);
% N=2; %debug

if N==0
    N=1;
end

numIds = length(frameIds);

if N<numIds
    for i=1:N
        frameIdsParallel{i} = frameIds(i:N:end);
    end
else
    N = numIds;
    for i=1:N
        frameIdsParallel{i} = frameIds(i);
    end
end


if ~exist('voxel','var')
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

    fprintf('memory x N = %f GB\n',  N * prod(voxel.size_grid) * 4 / (1024*1024*1024));
    fprintf('space = %.2f m x %.2f m x %.2f m ', voxel.size_grid(1) * voxel.unit, voxel.size_grid(2) * voxel.unit, voxel.size_grid(3) * voxel.unit);
    fprintf('= [%.2f,%.2f] x [%.2f,%.2f] x [%.2f,%.2f]\n',voxel.range(1,1),voxel.range(1,2),voxel.range(2,1),voxel.range(2,2),voxel.range(3,1),voxel.range(3,2));
end

%debug
parfor i=1:N
    [~,~,~,tsdf_value{i},tsdf_weight{i},tsdf_color{i}] = TSDFmesh(data, frameIdtarget,frameIdsParallel{i},cameraRtC2W, is_color, false, voxel);
end



for i=2:N  
    old_weight = tsdf_weight{1};
    g1= tsdf_weight{1}>0;
    gi= tsdf_weight{i}>0;
    
    sel = (~g1) & gi;
    tsdf_weight{1}(sel) = tsdf_weight{i}(sel);
    tsdf_value{1}(sel) = tsdf_value{i}(sel);
    
    sel = g1 & gi;
    
    tsdf_weight{1}(sel) = tsdf_weight{1}(sel) + tsdf_weight{i}(sel);
    tsdf_value{1}(sel) = (tsdf_value{1}(sel) .* old_weight(sel) + tsdf_value{i}(sel) .* tsdf_weight{i}(sel)) ./ tsdf_weight{1}(sel);
end


if is_color
    for i=1:N 
        tsdf_color{i} = reshape(typecast(tsdf_color{i}(:),'uint8'),[4 voxel.size_grid']);
    end
    
    for i=2:N 
        old_weight  = double(tsdf_color{1}(4,:,:,:));
        old_weight4 = repmat(old_weight,[4 1 1 1]);
        dlt_weight  = double(tsdf_color{i}(4,:,:,:));
        dlt_weight4 = repmat(dlt_weight,[4 1 1 1]);
        new_weight4 = max(1, old_weight4 + dlt_weight4);
        new_weight = uint8(min(255,old_weight+dlt_weight));

        tsdf_color{1} = uint8( round( ( double(tsdf_color{1}) .* double(old_weight4) + double(tsdf_color{i}) .* double(dlt_weight4) ) ./ new_weight4 ));
        tsdf_color{1}(4,:,:,:) = new_weight;
    end
    
    tsdf_color{1} = reshape(typecast(tsdf_color{1}(:),'uint32'),voxel.size_grid');
end

tsdf_value = tsdf_value{1};
tsdf_weight = tsdf_weight{1};
tsdf_color = tsdf_color{1};

if is_mesh    
    [XYZworld,faces, RGBcolor] = meshFromTSDF(voxel, tsdf_value, tsdf_color, is_color);    
else
    XYZworld = [];
    faces = [];
    RGBcolor = [];
end


patch2ply('debugMeshColorPar.ply', XYZworld, faces, RGBcolor);






