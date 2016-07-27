function depth = readDepth(data,frameID,RGBframe)

if ~exist('RGBframe','var')
    RGBframe = true;
end

if RGBframe
    depth = imread(data.depth{frameID});
else
    depth = imread(data.depthAll{frameID});
end
%depth = depth(:,end:-1:1,:);
depth = get_depth(depth);
%depth = denoise(depth,data.camera.D);
