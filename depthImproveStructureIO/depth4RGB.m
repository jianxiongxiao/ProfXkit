function [imageDepth, justUseFrameID, Rt_maxNeg2RGB, Rt_minPos2RGB, maxNegDepthFrameID, minPosDepthFrameID, maxNegValue, minPosValue] = depth4RGB(data, rgbFrameID)

% return a depth map that aligns with RGB color image at rgbFrameID using time interpolation


diff = double(data.depthTimestamp)-double(data.imageTimestamp(rgbFrameID));



maxNegValue = max(diff(diff<0));
minPosValue = min(diff(diff>=0));

if ~isempty(maxNegValue)
    maxNegDepthFrameID =find(diff==maxNegValue);
end

if ~isempty(minPosValue)
    minPosDepthFrameID =find(diff==minPosValue);
end

justUseFrameID = [];

if isempty(maxNegValue)
    justUseFrameID = minPosDepthFrameID;
elseif isempty(minPosValue)
    justUseFrameID = maxNegDepthFrameID;
elseif minPosValue==0
    justUseFrameID = minPosDepthFrameID;
end

if isempty(justUseFrameID)

    ratio = (-maxNegValue / (-maxNegValue+ minPosValue));
    minPosDepth = readDepth(data,minPosDepthFrameID,false);
    %minPosDepth = denoise(get_depth(imread(data.depthAll{minPosDepthFrameID})),data.camera.D);
    minPosXYZcamera(:,:,1)= data.camera.D.X .* minPosDepth;
    minPosXYZcamera(:,:,2)= data.camera.D.Y .* minPosDepth;
    minPosXYZcamera(:,:,3)= minPosDepth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
    minPosXYZcamera(:,:,4)= minPosDepth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);

    minPosXYZ = reshape(minPosXYZcamera,[],4)';
    minPosXYZ = minPosXYZ(1:3,minPosXYZ(3,:)>0);

    maxNegDepth = readDepth(data,maxNegDepthFrameID,false);
    %maxNegDepth = denoise(get_depth(imread(data.depthAll{maxNegDepthFrameID})),data.camera.D);
    maxNegXYZcamera(:,:,1)=data.camera.D.X .* maxNegDepth;
    maxNegXYZcamera(:,:,2)=data.camera.D.Y .* maxNegDepth;
    maxNegXYZcamera(:,:,3)=maxNegDepth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
    maxNegXYZcamera(:,:,4)=maxNegDepth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);
    maxNegXYZ = reshape(maxNegXYZcamera,[],4)';
    maxNegXYZ = maxNegXYZ(1:3,maxNegXYZ(3,:)>0);

    SmartRejection = 2;
    [R, t, ER, maxD] = icp(maxNegXYZ,minPosXYZ,'Matching','kDtree','SmartRejection',SmartRejection);

    angle_axis = RotationMatrix2AngleAxis(R);
    angle = sqrt(dot(angle_axis,angle_axis));
    if (angle > 0)
        angle_axis = angle_axis / angle;
    end

    % interpolating the angle
    angle_RGB = angle * ratio;
    angle_axis_RGB = angle_axis * angle_RGB;

    R_RGB = AngleAxis2RotationMatrix(angle_axis_RGB);
    t_RGB = t * ratio;

    Rt_RGB = [R_RGB t_RGB];

    % Rt interpolation
    Rt_maxNeg2interp = inverseRt(Rt_RGB);
    Rt_minPos2interp = concatenateRts(Rt_maxNeg2interp, [R t]);

    % Align with the color
    Rt_D2RGB = [data.camera.D2RGB.R data.camera.D2RGB.T];

    Rt_maxNeg2RGB = concatenateRts(Rt_D2RGB, Rt_maxNeg2interp);
    Rt_minPos2RGB = concatenateRts(Rt_D2RGB, Rt_minPos2interp);

    [~,maxNegImageDepth] = WarpDepthMatlab(maxNegXYZcamera,data.camera.RGB.K2render, Rt_maxNeg2RGB, data.camera.RGB.width, data.camera.RGB.height);
    [~,minPosImageDepth] = WarpDepthMatlab(minPosXYZcamera,data.camera.RGB.K2render, Rt_minPos2RGB, data.camera.RGB.width, data.camera.RGB.height);

    valid = maxNegImageDepth~=0 & minPosImageDepth~=0 & abs(maxNegImageDepth-minPosImageDepth)<0.05;

    imageDepth = (maxNegImageDepth + minPosImageDepth)/2;
    imageDepth(~(valid(:)))=0;

else
    depth = readDepth(data,justUseFrameID,false);
    %depth = denoise(get_depth(imread(data.depthAll{justUseFrameID})),data.camera.D);    
    XYZcamera(:,:,1)=data.camera.D.X .* depth;
    XYZcamera(:,:,2)=data.camera.D.Y .* depth;
    XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
    XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);    
    Rt = [data.camera.D2RGB.R data.camera.D2RGB.T];
    % Rt = inverseRt(Rt);
    [~,imageDepth] = WarpDepthMatlab(XYZcamera,data.camera.RGB.K2render, Rt, data.camera.RGB.width, data.camera.RGB.height);

    
    
    Rt_maxNeg2RGB = Rt;
    Rt_minPos2RGB = Rt;
    maxNegDepthFrameID = justUseFrameID;
    minPosDepthFrameID = justUseFrameID;

    
end

%imagesc(imageDepth); axis equal; axis tight; axis off;

