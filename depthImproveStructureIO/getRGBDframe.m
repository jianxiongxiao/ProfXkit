function frames = getRGBDframe(sequenceName,frameIDs, returnXYZ)

if ischar(sequenceName)
    data = loadSUN3Dv2(sequenceName);
else
    data = sequenceName;
end

if ~exist('returnXYZ','var')
    returnXYZ = true;
end

if ~exist('frameIDs','var') || isempty(frameIDs)
    frameIDs = 1:frameCount;
end

cnt = 0;
for frameID=frameIDs
    cnt = cnt + 1;
    image = readImage(data,frameID);   
    if isfield(data.camera.RGB,'kc')
        undistortImage = undistort_image(im2double(image), data.camera.RGB.KK, data.camera.RGB.kc, data.camera.RGB.width, data.camera.RGB.height, data.camera.RGB.K2render);
    else
        undistortImage = im2double(image);
    end
    frames(:,:,1,cnt) = undistortImage(:,:,1);
    frames(:,:,2,cnt) = undistortImage(:,:,2);
    frames(:,:,3,cnt) = undistortImage(:,:,3);
    
    
    if returnXYZ
        if isfield(data,'depthTimestamp')
            imageDepth = depth4RGB(data, frameID);    
        else
            imageDepth = readDepth(data,frameID,true);
        end
        [x,y] = meshgrid(0:(data.camera.RGB.width-1), 0:(data.camera.RGB.height-1));
        frames(:,:,4,cnt) = imageDepth;
        frames(:,:,5,cnt) = (x-data.camera.RGB.K2render(1,3)).*imageDepth/data.camera.RGB.K2render(1,1);
        frames(:,:,6,cnt) = (y-data.camera.RGB.K2render(2,3)).*imageDepth/data.camera.RGB.K2render(2,2);    
    end
end
