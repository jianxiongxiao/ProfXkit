function [depthRefined, image] = SiftFuv2warpFast(directory,frameIDtarget, interval)

data = loadStructureIOdata(directory,[]);

margin = 0;


% new structureIO
renderK = data.K;
im = imread(data.image{1});
renderW = size(im,2);
renderH = size(im,1);
data.camera.RGB.K2render = renderK;
data.camera.RGB.width    = renderW;
data.camera.RGB.height   = renderH;

data.camera.D2RGB.R = eye(3);
data.camera.D2RGB.T = zeros(3,1);
data.camera.D.width = renderW;
data.camera.D.height= renderH;

[x,y] = meshgrid(1:renderW, 1:renderH);
data.camera.D.X = (x-data.K(1,3))/data.K(1,1);
data.camera.D.Y = (y-data.K(2,3))/data.K(2,2);
data.imageTotalFrames = length(data.image);




frameIDs = max(frameIDtarget-interval,1):min(data.imageTotalFrames,frameIDtarget+interval);
targetFrame = getRGBDframe(data,frameIDtarget);



Rts = repmat([eye(3) zeros(3,1)],[1,1,length(frameIDs)]);

itarget = find(frameIDs==frameIDtarget);

DepthRt = zeros(3,4,0);
DepthID = [];

matched = false(1,length(frameIDs));
for i = 1:length(frameIDs)
    if i~=itarget
        fprintf('matching frame %d and frame %d\n',frameIDs(itarget),frameIDs(i));
        currentFrame = getRGBDframe(data,frameIDs(i));
        Rts(:,:,i) = align2RGBD(targetFrame,currentFrame);
        matched(i) = true;
    else
        Rts(:,:,i) = [eye(3) zeros(3,1)];
        matched(i) = true;
    end
    
    
    [imageDepth, justUseFrameID, Rt_maxNeg2RGB, Rt_minPos2RGB, maxNegDepthFrameID, minPosDepthFrameID, maxNegValue, minPosValue] = depth4RGB(data, frameIDs(i));

    if isempty(justUseFrameID)

        DepthID = [DepthID maxNegDepthFrameID];
        DepthRt(:,:,end+1) = concatenateRts(Rts(:,:,i), Rt_maxNeg2RGB);

        DepthID = [DepthID minPosDepthFrameID];
        DepthRt(:,:,end+1) = concatenateRts(Rts(:,:,i), Rt_minPos2RGB);
        
        
        if i==itarget
            if (-maxNegValue)< minPosValue
                targetDepthID = maxNegDepthFrameID;
            else
                targetDepthID = minPosDepthFrameID;
            end            
        end                
        
    else
        DepthID = [DepthID justUseFrameID];
        DepthRt(:,:,end+1) = concatenateRts(Rts(:,:,i), Rt_maxNeg2RGB);
        
        if i==itarget
            targetDepthID = justUseFrameID;
        end        
    end
end

allDepthID = unique(DepthID);

for i=1:length(allDepthID)
    loc = find(DepthID==allDepthID(i));
    loc = loc(floor((length(loc)+1)/2));
    
    
    depth = readDepth(data,DepthID(loc),false);
    XYZcamera(:,:,1)=data.camera.D.X .* depth;
    XYZcamera(:,:,2)=data.camera.D.Y .* depth;
    XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
    XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);    
    
    [~,undistortDepth(:,:,i)] = WarpDepthMatlab(XYZcamera,renderK, DepthRt(:,:,loc), renderW, renderH);
    if DepthID(loc)==targetDepthID
        depthRaw = undistortDepth(:,:,i);
    end
end


undistortDepth(undistortDepth(:)==0) = NaN;

depthMedian = nanmedian(undistortDepth,3);

countMedian = sum(~isnan(undistortDepth),3);
validMedian = countMedian> (size(undistortDepth,3)*0.25) |  countMedian> 10;

% to preserve details: check the value and the range of all values. if it is 25%-75%, keep the original values
disp('prctile...');
tic
minV = prctile(undistortDepth,75,3);
maxV = prctile(undistortDepth,25,3);
toc

image = ones(renderH,renderW,3);
image(margin+1:end-margin,:,:)= targetFrame(:,:,1:3);

selV = ((depthRaw < minV) | (depthRaw > maxV) | isnan(depthRaw)) & validMedian;
ind = find(selV);
depthRefined = depthRaw;
depthRefined(ind) = depthMedian(ind);

depthRefined(isnan(depthRefined(:)))=0;