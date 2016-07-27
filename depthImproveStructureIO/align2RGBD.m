function Rt = align2RGBD(RGBD1, RGBD2, PC1, PC2, error3D_threshold,SmartRejection,DISicpRatioTol , DISicpDisTol)

% given two RGBD image, we use SIFT + 3pt-RANSAC + ICP to estimate their relative location

% input:
% RGBD1(:,:,1) R   [0,1]
% RGBD1(:,:,2) G   [0,1]
% RGBD1(:,:,3) B   [0,1]
% RGBD1(:,:,4) D=Z unit=meter
% RGBD1(:,:,5) X   unit=meter
% RGBD1(:,:,6) Y   unit=meter

% RGBD2(:,:,1) R   [0,1]
% RGBD2(:,:,2) G   [0,1]
% RGBD2(:,:,3) B   [0,1]
% RGBD2(:,:,4) D=Z unit=meter
% RGBD2(:,:,5) X   unit=meter
% RGBD2(:,:,6) Y   unit=meter

% example usage:
% load debug.mat; Rt = align2RGBD(frames(:,:,:,1), frames(:,:,:,2));

basicSetup;


if ~exist('error3D_threshold','var')
    error3D_threshold = 0.05;
end

if ~exist('SmartRejection','var')
    SmartRejection = 2;
end

if ~exist('DISicpRatioTol','var')
    DISicpRatioTol = 2;
end

if ~exist('DISicpDisTol','var')
    DISicpDisTol = 0.1;
end



[Frame_i,SIFTdes_i] = up_sift(single(rgb2gray(RGBD1(:,:,1:3))));
SIFTloc_i = Frame_i([2,1],:);
[Frame_j,SIFTdes_j] = up_sift(single(rgb2gray(RGBD2(:,:,1:3))));
SIFTloc_j = Frame_j([2,1],:);



%% SIFT matching
 
%[matchPointsID_i, matchPointsID_j] = matchSIFTdesImages(SIFTdes_i, SIFTdes_j);
[matchPointsID_i, matchPointsID_j] = matchSIFTdesImagesBidirectional(SIFTdes_i, SIFTdes_j);

minNeighboringFrame = 0; % used to be 3, hack to bypass matlab error
minNeighboringMatching = 200;

%if abs(frameID_i-frameID_j)<=minNeighboringFrame
    if length(matchPointsID_i)<minNeighboringMatching
        fprintf(' too few matching (%d) => relax SIFT threhsold to 0.7 ', length(matchPointsID_i));
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
%end

SIFTloc_i = SIFTloc_i(:,matchPointsID_i);
SIFTloc_j = SIFTloc_j(:,matchPointsID_j);
        
posSIFT_i = round(SIFTloc_i);
valid_i = (1<=posSIFT_i(1,:)) & (posSIFT_i(1,:)<=size(RGBD1,1)) & (1<=posSIFT_i(2,:)) & (posSIFT_i(2,:)<=size(RGBD1,2));
posSIFT_j = round(SIFTloc_j);
valid_j = (1<=posSIFT_j(1,:)) & (posSIFT_j(1,:)<=size(RGBD2,1)) & (1<=posSIFT_j(2,:)) & (posSIFT_j(2,:)<=size(RGBD2,2));
valid = valid_i & valid_j;

posSIFT_i = posSIFT_i(:,valid);
SIFTloc_i = SIFTloc_i(:,valid);
posSIFT_j = posSIFT_j(:,valid);
SIFTloc_j = SIFTloc_j(:,valid);
        
        
Xcam_i   = RGBD1(:,:,5);
Ycam_i   = RGBD1(:,:,6);
Zcam_i   = RGBD1(:,:,4);
validM_i = RGBD1(:,:,4)~=0;
ind_i = sub2ind([size(RGBD1,1) size(RGBD1,2)],posSIFT_i(1,:),posSIFT_i(2,:));
valid_i = validM_i(ind_i);

Xcam_j   = RGBD2(:,:,5);
Ycam_j   = RGBD2(:,:,6);
Zcam_j   = RGBD2(:,:,4);
validM_j = RGBD2(:,:,4)~=0;
ind_j = sub2ind([size(RGBD2,1) size(RGBD2,2)],posSIFT_j(1,:),posSIFT_j(2,:));
valid_j = validM_j(ind_j);

valid = valid_i & valid_j;

ind_i = ind_i(valid);
P3D_i = [Xcam_i(ind_i); Ycam_i(ind_i); Zcam_i(ind_i)];
ind_j = ind_j(valid);
P3D_j = [Xcam_j(ind_j); Ycam_j(ind_j); Zcam_j(ind_j)];


SIFTloc_i = SIFTloc_i(:,valid);
SIFTloc_j = SIFTloc_j(:,valid);

%{     
figure(1)
imshow(RGBD1(:,:,1:3));
hold on
plot(SIFTloc_i(2,:),SIFTloc_i(1,:),'+g');
drawnow
figure(2)
imshow(RGBD2(:,:,1:3));
hold on
plot(SIFTloc_j(2,:),SIFTloc_j(1,:),'+g');
drawnow
%}

%% align RANSAC
matchSIFT_threshold = 4;


[RtRANSAC, inliers] = ransacfitRt([P3D_i; P3D_j], error3D_threshold, 0);

if length(inliers)<matchSIFT_threshold
    throw(MException('robustAlignRt:RANSAC', 'RANSAC fails to find enough inliers'));
end

if exist('PC1','var')
    dense3DFrom = PC1;
else
    dense3DFrom = [Xcam_i(validM_i(:)) Ycam_i(validM_i(:)) Zcam_i(validM_i(:))]';
end

if exist('PC2','var')
    dense3DTo   = PC2;
else
    dense3DTo   = [Xcam_j(validM_j(:)) Ycam_j(validM_j(:)) Zcam_j(validM_j(:))]';
end

% ICP refinement to get a new RtRANSAC
[TR, TT, ER, maxD] = icp(dense3DFrom,transformPointCloud(dense3DTo,RtRANSAC),'Matching','kDtree','SmartRejection',SmartRejection);
%ER
%maxD


% test if the icp destroy everything by checking SIFT distance
SIFTfrom  = P3D_i(:,inliers);
SIFTto    = P3D_j(:,inliers);
SIFTransac= transformPointCloud(SIFTto,RtRANSAC);
SIFTicp   = transformPointCloud(SIFTto,mulRt([TR TT],RtRANSAC));

DISransac = mean(sqrt(sum((SIFTfrom-SIFTransac).^2,1)));
DISicp    = mean(sqrt(sum((SIFTfrom-SIFTicp   ).^2,1)));

fprintf('RANSAC %f (%d/%d=%f) => ICP %f (%f=>%f, %f=>%f)\n',DISransac,length(inliers),size(P3D_i,2),length(inliers)/size(P3D_i,2),DISicp,ER(1),ER(end),maxD(1),maxD(end));
if DISicp>DISransac && (DISicp > DISransac*DISicpRatioTol || DISicp > DISicpDisTol)
    Rt = RtRANSAC;
    disp('ICP is bad. Only using RANSAC');
else
    Rt = mulRt([TR TT],RtRANSAC);
end

% debug
%points2ply('align2RGBD.ply', [dense3DFrom transformPointCloud(SIFTto,Rt)]);



end