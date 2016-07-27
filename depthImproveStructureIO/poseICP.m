function Rts = poseICP(sequenceName)

if ~exist('sequenceName','var')
    sequenceName = '2014-04-29_14-37-21_094959634447';
end

data = loadSUN3Dv2(sequenceName);

Rts = repmat([eye(3) zeros(3,1)],[1,1,data.depthTotalFrames]);


SmartRejection = 2;

for frameID=1:data.depthTotalFrames
    depth = readDepth(data,frameID,false);
    XYZcamera(:,:,1)=data.camera.D.X .* depth;
    XYZcamera(:,:,2)=data.camera.D.Y .* depth;
    XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
    XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);
    valid = logical(XYZcamera(:,:,4));
    valid = valid(:)';
    XYZ = reshape(XYZcamera,[],4)';
    XYZ = XYZ(1:3,valid);
    
    if frameID>1
        fprintf('%d/%d: ',frameID, data.depthTotalFrames);
        [R, t, ER, maxD] = icp(XYZold,XYZ,'Matching','kDtree','SmartRejection',SmartRejection);
        Rts(:,:,frameID) = concatenateRts(Rts(:,:,frameID-1),[R t]);
    end
    
    XYZold = XYZ;
end


%% output to ply

totalFrames = 20;
deltaFrames = max(1,round(data.depthTotalFrames/totalFrames));

ptsAll = [];
for frameID=1:deltaFrames:data.depthTotalFrames
    depth = readDepth(data,frameID,false);
    XYZcamera(:,:,1)=data.camera.D.X .* depth;
    XYZcamera(:,:,2)=data.camera.D.Y .* depth;
    XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
    XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);
    valid = logical(XYZcamera(:,:,4));
    valid = valid(:)';
    XYZ = reshape(XYZcamera,[],4)';
    XYZ = XYZ(1:3,valid);
    
    pts = transformPointCloud(XYZ,Rts(:,:,frameID));    
    
    ptsAll = [ptsAll pts];
    % rgbAll = [rgbAll rgb];
end

points2ply('demo_icp.ply', ptsAll);
