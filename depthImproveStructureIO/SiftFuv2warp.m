function depthRefined = SiftFuv2warp(sequenceName,frameIDtarget, interval, renderK, renderW, renderH)

if ~exist('sequenceName','var')
    sequenceName = 'Shuran/bedroom_funiturestore/2014-05-26_14-41-22_260595134347';
end

if ~exist('frameIDtarget','var')
    frameIDtarget = 34; %200;
end

if ~exist('interval','var')
    interval = 150;
end

data = loadSUN3Dv2(sequenceName);

frameIDs = max(frameIDtarget-interval,1):min(data.imageTotalFrames,frameIDtarget+interval);

frames = getRGBDframe(data,frameIDs);

Rts = repmat([eye(3) zeros(3,1)],[1,1,length(frameIDs)]);

itarget = find(frameIDs==frameIDtarget);

%{
depthOriginal = get_depth(imread(data.depth{frameIDs(itarget)}));
depth = denoise(depthOriginal,data.camera.D);
PCtarget(1,:)=reshape(data.camera.D.X .* depth,1,[]);
PCtarget(2,:)=reshape(data.camera.D.Y .* depth,1,[]);
PCtarget(3,:)=reshape(depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y)),1,[]);
PCtarget = PCtarget(:, PCtarget(3,:)>0);    
%}

matched = false(1,length(frameIDs));
for i = 1:length(frameIDs)
    if i~=itarget
        fprintf('matching frame %d and frame %d\n',frameIDs(itarget),frameIDs(i));
        Rts(:,:,i) = align2RGBD(frames(:,:,:,itarget), frames(:,:,:,i));
        matched(i) = true;
        %{
        depth = get_depth(imread(data.depth{frameIDs(i)}));
        depth = denoise(depth,data.camera.D);
        clear PCi
        PCi(1,:)=reshape(data.camera.D.X .* depth,1,[]);
        PCi(2,:)=reshape(data.camera.D.Y .* depth,1,[]);
        PCi(3,:)=reshape(depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y)),1,[]);
        PCi = PCi(:, PCi(3,:)>0);            

        try
            Rts(:,:,i) = align2RGBD(frames(:,:,:,itarget), frames(:,:,:,i), PCtarget, PCi);
            matched(i) = true;
        catch
        end
        %}
    end
end


% old Kinect
%renderK = [519.1638 0 320; 0 519.1638 240; 0 0 1];
if ~exist('renderK','var')
    renderK = data.camera.RGB.K2render; %[519 0 320; 0 519 240; 0 0 1];
end
if ~exist('renderW','var')
    renderW = data.camera.RGB.width; %640;
end
if ~exist('renderH','var')
    renderH = data.camera.RGB.height; %480;
end

% new Kinect
%{
renderK = data.camera.D.KK;
renderW = data.camera.D.width;
renderH = data.camera.D.height;
%}


for i=1:length(frameIDs)   
    if matched(i) || i==itarget
        frameID=frameIDs(i);
        
        XYZcamera = frames(:,:,[5 6 4],i);
        XYZcamera(:,:,4) = XYZcamera(:,:,3)>0;
        %{
        depth = get_depth(imread(data.depth{frameID}));
        XYZcamera(:,:,1)=data.camera.D.X .* depth;
        XYZcamera(:,:,2)=data.camera.D.Y .* depth;
        XYZcamera(:,:,3)=depth .* (~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y));
        XYZcamera(:,:,4)=depth>0 & ~isnan(data.camera.D.X) & ~isnan(data.camera.D.Y);
        %}

        [~,undistortDepth(:,:,i)] = WarpDepthMatlab(XYZcamera, renderK, Rts(:,:,i), renderW, renderH);
    end
end

undistortDepth(undistortDepth(:)==0) = NaN;

%depthRefined = nanmean(undistortDepth,3);
depthMedian = nanmedian(undistortDepth,3);

% to preserve details: check the value and the range of all values. if it is 25%-75%, keep the original values
minV = prctile(undistortDepth,75,3);
maxV = prctile(undistortDepth,25,3);
depthRaw = undistortDepth(:,:,itarget);

selV = (depthRaw < minV) | (depthRaw > maxV) | isnan(depthRaw);
ind = find(selV);
depthRefined = depthRaw;
depthRefined(ind) = depthMedian(ind);

depthRefined(isnan(depthRefined(:)))=0;

%{
[x,y] = meshgrid(1:renderW, 1:renderH);
clear X
X(1,:) = reshape((x-renderK(1,3)).*depthRefined/renderK(1,1),1,[]);
X(2,:) = reshape((y-renderK(2,3)).*depthRefined/renderK(2,2),1,[]);
X(3,:) = reshape(depthRefined,1,[]);
X = X(:,~isnan(depthRefined(:)));


% turn

figure;
subplot(2,2,1);
imagesc(depthOriginal,[0 20]); axis equal; axis tight; axis off; title('raw TOF depth');

subplot(2,2,2);
imagesc(depthRefined,[0 20]); axis equal; axis tight; axis off; title('undistorted denoised depth');

points2ply('pt_denoise101.ply', X);
%}
