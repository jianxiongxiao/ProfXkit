function pair = align2view(frameID_i,image_i,XYZcam_i,frameID_j,image_j,XYZcam_j)
error3D_threshold = 0.05;
error3D_threshold2 = error3D_threshold^2;



%% load two images and depths

%% compute SIFT keypoints

%{
    [SIFTdes_i, SIFTloc_i] = siftDavidLowe(image_i);
    SIFTdes_i = SIFTdes_i';
    SIFTloc_i = SIFTloc_i';
    [SIFTdes_j, SIFTloc_j] = siftDavidLowe(image_j);
    SIFTdes_j = SIFTdes_j';
    SIFTloc_j = SIFTloc_j';
%}    
    
[SIFTloc_i,SIFTdes_i] = vl_sift(single(rgb2gray(image_i))) ;
SIFTloc_i = SIFTloc_i([2,1],:);
[SIFTloc_j,SIFTdes_j] = vl_sift(single(rgb2gray(image_j))) ;
SIFTloc_j = SIFTloc_j([2,1],:);



%% SIFT matching
 
%[matchPointsID_i, matchPointsID_j] = matchSIFTdesImages(SIFTdes_i, SIFTdes_j);
[matchPointsID_i, matchPointsID_j] = matchSIFTdesImagesBidirectional(SIFTdes_i, SIFTdes_j);

minNeighboringFrame = 0; % used to be 3, hack to bypass matlab error
minNeighboringMatching = 20;

if abs(frameID_i-frameID_j)<=minNeighboringFrame
    if length(matchPointsID_i)<minNeighboringMatching
        fprintf('frame %d + %d: too few matching (%d) => relax SIFT threhsold to 0.7 ', frameID_i, frameID_j , length(matchPointsID_i));
        [matchPointsID_i, matchPointsID_j] = matchSIFTdesImagesBidirectional(SIFTdes_i, SIFTdes_j, 0.7^2);
        if length(matchPointsID_i)<minNeighboringMatching
            fprintf('with %d matching => relax SIFT threhsold to 0.8 ', length(matchPointsID_i));
            [matchPointsID_i, matchPointsID_j] = matchSIFTdesImagesBidirectional(SIFTdes_i, SIFTdes_j, 0.8^2);
            if length(matchPointsID_i)<minNeighboringMatching
                fprintf('with %d matching => relax SIFT threhsold to 0.9 ', length(matchPointsID_i));
                [matchPointsID_i, matchPointsID_j] = matchSIFTdesImagesBidirectional(SIFTdes_i, SIFTdes_j, 0.9^2);
                if length(matchPointsID_i)<minNeighboringMatching
                    fprintf('with %d matching => relax SIFT threhsold to 0.95 ', length(matchPointsID_i));
                    [matchPointsID_i, matchPointsID_j] = matchSIFTdesImagesBidirectional(SIFTdes_i, SIFTdes_j, 0.95^2);
                end
            end
        end
        fprintf('with %d matching \n', length(matchPointsID_i));
    end
end

SIFTloc_i = SIFTloc_i(:,matchPointsID_i);
SIFTloc_j = SIFTloc_j(:,matchPointsID_j);
        
posSIFT_i = round(SIFTloc_i);
valid_i = (1<=posSIFT_i(1,:)) & (posSIFT_i(1,:)<=size(image_i,1)) & (1<=posSIFT_i(2,:)) & (posSIFT_i(2,:)<=size(image_i,2));
posSIFT_j = round(SIFTloc_j);
valid_j = (1<=posSIFT_j(1,:)) & (posSIFT_j(1,:)<=size(image_i,1)) & (1<=posSIFT_j(2,:)) & (posSIFT_j(2,:)<=size(image_i,2));
valid = valid_i & valid_j;

posSIFT_i = posSIFT_i(:,valid);
SIFTloc_i = SIFTloc_i(:,valid);
posSIFT_j = posSIFT_j(:,valid);
SIFTloc_j = SIFTloc_j(:,valid);
        
        
Xcam_i = XYZcam_i(:,:,1);
Ycam_i = XYZcam_i(:,:,2);
Zcam_i = XYZcam_i(:,:,3);
validM_i = logical(XYZcam_i(:,:,4));
ind_i = sub2ind([size(image_i,1) size(image_i,2)],posSIFT_i(1,:),posSIFT_i(2,:));
valid_i = validM_i(ind_i);

Xcam_j = XYZcam_j(:,:,1);
Ycam_j = XYZcam_j(:,:,2);
Zcam_j = XYZcam_j(:,:,3);
validM_j = logical(XYZcam_j(:,:,4));
ind_j = sub2ind([size(image_i,1) size(image_i,2)],posSIFT_j(1,:),posSIFT_j(2,:));
valid_j = validM_j(ind_j);

valid = valid_i & valid_j;

ind_i = ind_i(valid);
P3D_i = [Xcam_i(ind_i); Ycam_i(ind_i); Zcam_i(ind_i)];
ind_j = ind_j(valid);
P3D_j = [Xcam_j(ind_j); Ycam_j(ind_j); Zcam_j(ind_j)];


SIFTloc_i = SIFTloc_i(:,valid);
SIFTloc_j = SIFTloc_j(:,valid);

global toVisualize

if toVisualize
    subplot(3,4,8)
    imshow(image_i);
    hold on
    plot(SIFTloc_i(2,:),SIFTloc_i(1,:),'+g');
    title('SIFT matching')
    subplot(3,4,4)
    imshow(image_j);
    hold on
    plot(SIFTloc_j(2,:),SIFTloc_j(1,:),'+g');
    title('SIFT matching')
end

%% align RANSAC

try
    [RtRANSAC, inliers] = ransacfitRt([P3D_i; P3D_j], error3D_threshold, 0);
    fprintf('frame %d + %d: # ransac inliers = %d/%d = %f%%', frameID_i, frameID_j, length(inliers), size(P3D_i,2), length(inliers)/size(P3D_i,2)*100);
    
    if abs(frameID_i-frameID_j)<=minNeighboringFrame
        %check the score
        [agreeRatio, averageDistance, goodpixels, pt]=depthConsistencyParallel(RtRANSAC,0.1, XYZcam_i, XYZcam_j, frames.K);
        % && length(inliers)<minNeighboringMatching
        % run ICP
        if goodpixels < 0.3
            
            RtRANSAC = fitRtByICP(XYZcam_i, XYZcam_j);
            agreeRatioOld = agreeRatio;
            [agreeRatio, averageDistance, goodpixels, pt]=depthConsistencyParallel(RtRANSAC,0.1, XYZcam_i, XYZcam_j, frames.K);
            fprintf(' ICP %f => %f ', agreeRatioOld, agreeRatio);  
            
            if goodpixels < 0.3 || agreeRatio < 0.95            
                RtRANSAC = [eye(3) zeros(3,1)];
                fprintf(' [I|0] %f ', goodpixels);            
            end
        elseif agreeRatio < 0.95
            RtRANSAC = fitRtByICP(XYZcam_i, XYZcam_j);
            agreeRatioOld = agreeRatio;
            [agreeRatio, averageDistance, goodpixels, pt]=depthConsistencyParallel(RtRANSAC,0.1, XYZcam_i, XYZcam_j, frames.K);
            fprintf(' ICP %f => %f ', agreeRatioOld, agreeRatio);            
        end
    end
catch
    
    %[RtRANSAC, inliers] = ransacfitRtDepthParallel([P3D_i; P3D_j], error3D_threshold, 1, XYZcam_i, XYZcam_j, frames.K);

    fprintf('frame %d + %d: # ransac FAILURE = 0/%d = %f%%', frameID_i, frameID_j, size(P3D_i,2), 0);
    fprintf(' [I|0]');
    
    RtRANSAC = [eye(3) zeros(3,1)];
end
fprintf('\n');

%{
if size(P3D_i,2)>15
    try
        %[RtRANSAC, inliers] = ransacfitRtDepthParallel([P3D_i; P3D_j], error3D_threshold, 1, XYZcam_i, XYZcam_j, frames.K);
        [RtRANSAC, inliers] = ransacfitRt([P3D_i; P3D_j], error3D_threshold, 0);
        fprintf('frame %d + %d: # ransac inliers = %d/%d = %f%%\n', frameID_i, frameID_j, length(inliers), size(P3D_i,2), length(inliers)/size(P3D_i,2)*100);
    catch
        RtRANSAC = [eye(3) zeros(3,1)];
    end
else
    RtRANSAC = [eye(3) zeros(3,1)];
end
%}

if ~isempty(P3D_i) && ~isempty(P3D_j)
    valid = (sum((P3D_i - transformRT(P3D_j, RtRANSAC, false)).^2,1) < error3D_threshold2);     % Indices of inlying points
    SIFTloc_i = SIFTloc_i(:,valid);
    P3D_i     = P3D_i    (:,valid);
    SIFTloc_j = SIFTloc_j(:,valid);
    P3D_j     = P3D_j    (:,valid);
end

%% bundle adjustment

pair.Rt = RtRANSAC;
pair.matches = [SIFTloc_i([2 1],:);P3D_i;SIFTloc_j([2 1],:);P3D_j];
pair.i = frameID_i;
pair.j = frameID_j;
