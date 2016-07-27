function depthRefined = refineDepthICP(sequenceName,frameIDtarget, interval, renderK, renderW, renderH)

if ~exist('sequenceName','var')
    sequenceName = '2014-04-11_17-09-54_094959634447';
end

if ~exist('frameIDtarget','var')
    frameIDtarget = 50; %200;
end

if ~exist('interval','var')
    interval = 50;
end

data = loadSUN3Dv2(sequenceName);


% old Kinect
%renderK = [519.1638 0 320; 0 519.1638 240; 0 0 1];
if ~exist('renderK','var')
    renderK = [1035 0 768; 0 1035 636; 0 0 1]; %[690 0 512; 0 690 424; 0 0 1]; %data.camera.RGB.K2render; %[519 0 320; 0 519 240; 0 0 1];
end
if ~exist('renderW','var')
    renderW = 1536; %1024; %data.camera.RGB.width; %640;
end
if ~exist('renderH','var')
    renderH =  1272; %848; %data.camera.RGB.height; %480;
end



frameIDs = max(frameIDtarget-interval,1):min(data.imageTotalFrames,frameIDtarget+interval);

Rts = repmat([eye(3) zeros(3,1)],[1,1,length(frameIDs)]);

itarget = find(frameIDs==frameIDtarget);

SmartRejection = 2;
matched = false(1,length(frameIDs));

for i=[itarget:length(frameIDs) itarget:-1:1]
    frameID = frameIDs(i);
    depth = readDepth(data,frameID,false);
    XYZcamera(:,:,1)=data.camera.D.X .* depth;
    XYZcamera(:,:,2)=data.camera.D.Y .* depth;
    XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));    
    XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);
    valid = logical(XYZcamera(:,:,4));  
    valid = valid(:)';        
    XYZ = reshape(XYZcamera,[],4)';
    XYZ = XYZ(1:3,valid);    
    
    if i==itarget
        XYZtarget = XYZ;
    elseif i>itarget
        [R, t, ER, maxD] = icp(XYZold,XYZ,'Matching','kDtree','SmartRejection',SmartRejection);
        matched(i) = true;        
        Rts(:,:,i) = concatenateRts(Rts(:,:,i-1),[R t]);
    
        [R, t, ER, maxD] = icp(XYZtarget,transformPointCloud(XYZ,Rts(:,:,i)),'Matching','kDtree','SmartRejection',SmartRejection);
        Rts(:,:,i) = concatenateRts([R t],Rts(:,:,i));

    elseif i<itarget
        [R, t, ER, maxD] = icp(XYZold,XYZ,'Matching','kDtree','SmartRejection',SmartRejection);
        matched(i) = true;
        
        Rts(:,:,i) = concatenateRts(Rts(:,:,i+1),[R t]);

        [R, t, ER, maxD] = icp(XYZtarget,transformPointCloud(XYZ,Rts(:,:,i)),'Matching','kDtree','SmartRejection',SmartRejection);
        Rts(:,:,i) = concatenateRts([R t],Rts(:,:,i));
    end
    
    XYZold = XYZ;
end


for i=1:length(frameIDs)   
    if matched(i) || i==itarget
        frameID = frameIDs(i);
        depth = readDepth(data,frameID,false);
        XYZcamera(:,:,1)=data.camera.D.X .* depth;
        XYZcamera(:,:,2)=data.camera.D.Y .* depth;
        XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));    
        XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);

        [~,undistortDepth(:,:,i)] = WarpDepthMatlab(XYZcamera, renderK, Rts(:,:,i), renderW, renderH);
    end
end

undistortDepth(undistortDepth(:)==0) = NaN;

%depthRefined = nanmean(undistortDepth,3);
fprintf('median filtering ...');
tic;
depthMedian = nanmedian(undistortDepth,3);
toc;

% to preserve details: check the value and the range of all values. if it is 25%-75%, keep the original values
fprintf('prctile filtering ...');
tic;
maxV = prctile(undistortDepth,75,3);
toc;
fprintf('prctile filtering ...');
tic;
minV = prctile(undistortDepth,25,3);
toc;
depthRaw = undistortDepth(:,:,itarget);

validCount = sum(double(~isnan(undistortDepth)),3);

selV = ((depthRaw < minV) | (depthRaw > maxV) | isnan(depthRaw)) & (validCount> max(3,0.25*(length(frameIDs)-1)));
ind = find(selV);
depthRefined = depthRaw;
depthRefined(ind) = depthMedian(ind);

depthRefined(isnan(depthRefined(:)))=0;

