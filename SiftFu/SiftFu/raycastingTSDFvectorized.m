function [VMap,NMap,tMap,CMap] = raycastingTSDFvectorized(camRtC2W, castingRange)

% VMap and NMap are in the world coordinate

% DDA based ray casting

global raycastingDirectionC;
global voxel;
global tsdf_value;

num_directions = size(raycastingDirectionC,2);

camCenterW = getCameraCenter(camRtC2W);
raycastingDirectionW = transformRTdir(raycastingDirectionC,camRtC2W);


raycastingDirectionWinv = raycastingDirectionW.^-1;
tt = sort(cat(3, repmat(voxel.range(:,1) + repmat(voxel.unit,3,1) - camCenterW,1,num_directions), repmat(voxel.range(:,2) - repmat(voxel.unit,3,1) - camCenterW,1,num_directions)) .* repmat(raycastingDirectionWinv,[1,1,2]),3);
tnearArray =  max(max(tt(:,:,1),[],1), castingRange(1));
tfarArray =  min(min(tt(:,:,2),[],1), castingRange(2));


camCenterWgrid = (camCenterW - voxel.range(:,1)) / voxel.unit + 1;

tMap = NaN(1,640*480);
NMap = NaN(3,640*480);
CMap = NaN(3,640*480);

step = voxel.unit;
largestep = 0.75 * voxel.mu;

%tPrev = 0;

tMap = single(NaN(1,640*480));
raycast(tMap, single(raycastingDirectionW/voxel.unit), single(tnearArray), single(tfarArray), single(camCenterWgrid-1), tsdf_value, size(tsdf_value,1), size(tsdf_value,2),step, largestep);


% computer vertex map
VMap = repmat(camCenterW,1,640*480) + raycastingDirectionW .* (repmat(tMap,3,1));

