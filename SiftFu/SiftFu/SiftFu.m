function newDepth = SiftFu(sequenceName, frameIDs)

%{
Please cite the following paper if you use this code

Citation:
J. Xiao, A. Owens and A. Torralba
SUN3D Database: Semantic RGB-D Bundle Adjustment with Human in the Loop
Proceedings of 14th IEEE International Conference on Computer Vision (ICCV2013)
%}


addpath(genpath('SIFTransac'))
vl_setup;

global toVisualize;
toVisualize = true;

%% IO
if ~exist('sequenceName','var')
    % load demo sequence
    % look for all sequence name list at http://sun3d.csail.mit.edu/player/list.html
    %sequenceName = 'hotel_mr/scan1';
    %sequenceName = 'hotel_umd/maryland_hotel3';
    %sequenceName = 'brown_bm_1/brown_bm_1';
    sequenceName = 'mit_32_d428/bs4j179mmv';
end

% the root path of SUN3D
% change it to local if you downloaded the data
%SUN3Dpath = '/data/vision/torralba/sun3d/record/scene_final';
SUN3Dpath = 'http://sun3d.csail.mit.edu/data/';

% read intrinsic
global K;
K = reshape(readValuesFromTxt(fullfile(SUN3Dpath,sequenceName,'intrinsics.txt')),3,3)';

% file list
imageFiles = dirSmart(fullfile(SUN3Dpath,sequenceName,'image/'),'jpg');
depthFiles = dirSmart(fullfile(SUN3Dpath,sequenceName,'depth/'),'png');

% read time stamp
imageFrameID = zeros(1,length(imageFiles));
imageTimestamp = zeros(1,length(imageFiles));
for i=1:length(imageFiles)
    id_time = sscanf(imageFiles(i).name, '%d-%d.jpg');
    imageFrameID(i) = id_time(1);
    imageTimestamp(i) = id_time(2);
end
depthFrameID = zeros(1,length(depthFiles));
depthTimestamp = zeros(1,length(depthFiles));
for i=1:length(depthFiles)
    id_time = sscanf(depthFiles(i).name, '%d-%d.png');
    depthFrameID(i) = id_time(1);
    depthTimestamp(i) = id_time(2);
end

% synchronize: find a depth for each image
frameCount = length(imageFiles);
IDimage2depth = zeros(1,frameCount);
for i=1:frameCount
    [~, IDimage2depth(i)]=min(abs(double(depthTimestamp)-double(imageTimestamp(i))));
end

%plot(double(imageTimestamp)-double(depthTimestamp(IDimage2depth)))

if ~exist('frameIDs','var')
    frameIDs = 1:frameCount;
else
    frameIDs = frameIDs(frameIDs>=1 & frameIDs<=frameCount);
end

imageFiles = imageFiles(frameIDs);
depthFiles = depthFiles(IDimage2depth(frameIDs));


%% kinect fusion

% for optimization

global VMap;
global NMap;
global CMap;

global XYZcam;
global Ncam;
global IMGcam;


%% tsdf


global voxel;
global tsdf_value;
global tsdf_weight;
global tsdf_color;    tsdf_color = [];


voxel.unit = 0.01; % Kevin: 4mm = 0.004 meter. Kinect cannot go better than 3mm
voxel.mu_grid = 10; % used to be 4
voxel.size_grid = [512; 512; 1024]; % [512; 512; 512];

voxel.range(1,1) = - voxel.size_grid(1) * voxel.unit / 2;
voxel.range(1,2) = voxel.range(1,1) + (voxel.size_grid(1)-1) * voxel.unit;

voxel.range(2,1) = - voxel.size_grid(2) * voxel.unit / 2;
voxel.range(2,2) = voxel.range(2,1) + (voxel.size_grid(2)-1) * voxel.unit;

voxel.range(3,1) = -0.5; % - voxel.size_grid(3) * voxel.unit / 2;
voxel.range(3,2) = voxel.range(3,1) + (voxel.size_grid(3)-1) * voxel.unit;

voxel.mu = voxel.mu_grid * voxel.unit;

fprintf('memory = %f GB\n',  prod(voxel.size_grid) * 4 / (1024*1024*1024));
fprintf('space = %.2f m x %.2f m x %.2f m ', voxel.size_grid(1) * voxel.unit, voxel.size_grid(2) * voxel.unit, voxel.size_grid(3) * voxel.unit);
fprintf('= [%.2f,%.2f] x [%.2f,%.2f] x [%.2f,%.2f]\n',voxel.range(1,1),voxel.range(1,2),voxel.range(2,1),voxel.range(2,2),voxel.range(3,1),voxel.range(3,2));


%tsdf_value  = -ones([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');
tsdf_value  =  ones([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');
tsdf_weight = zeros([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)],'single');

% comment out this line to avoid using color
% tsdf_color  = zeros([voxel.size_grid(1),voxel.size_grid(2), voxel.size_grid(3)], 'uint32');




f = K(1,1);

global ViewFrustumC;
ViewFrustumC = [...
    0 -320 -320  320  320;
    0 -240  240  240 -240;
    0    f    f    f    f];
ViewFrustumC = ViewFrustumC/f * 8; % 8 meter is the furthest depth of kinect

% precompute
global raycastingDirectionC;
[pX,pY]=meshgrid(1:640,1:480);

raycastingDirectionC = [pX(:)'-K(1,3); pY(:)'-K(2,3); f*ones(1,640*480)]; % clipping at 8 meter is the furthest depth of kinect
raycastingDirectionC = raycastingDirectionC ./ repmat(sqrt(sum(raycastingDirectionC.^2,1)),3,1);

%%
useSIFT = false;
if useSIFT
    MatchPairs = cell(1,length(imageFiles)-1);
end

cameraRtC2W = repmat([eye(3) zeros(3,1)], [1,1,length(imageFiles)]);

dispclim = [0 5];

for frameID = 1:length(imageFiles)
    
    fprintf('================================ Frame %d ================================\n',frameID);
    
    
    IMGcam = imageRead(fullfile(fullfile(SUN3Dpath,sequenceName,'image',imageFiles(frameID).name)));

    %subplot(3,4,4)
    %imagesc(IMGcam);  axis equal; axis tight; 
    %drawnow;
    %title('input color');

    if frameID==1
        IMGcam1 = IMGcam;
    end

    
    % read the frame
    
    depth = depthRead(fullfile(fullfile(SUN3Dpath,sequenceName,'depth',depthFiles(frameID).name)));
    XYZcam = depth2XYZcamera(K, depth);
    
    if frameID==1
        XYZcam1 = XYZcam;
    end
    
    
    Ncam = vertex2normal(XYZcam);
    
    
    if toVisualize
        if frameID==1    
            subplot(3,4,9)
        else
            subplot(3,4,1)
        end
        imagesc(XYZcam(:,:,3),dispclim); axis equal; axis tight
        title(sprintf('Frame %d: Input Depth',frameID));
        axis off

        if frameID==1
            subplot(3,4,10)
        else
            subplot(3,4,2)
        end
        imagesc((Ncam+1)/2); axis equal; axis tight
        title(sprintf('Frame %d: Input Normal',frameID));
        axis off

        if frameID==1
            subplot(3,4,11)
        else
            subplot(3,4,3)
        end
        raycastingDirectionW = transformRTdir(raycastingDirectionC,[eye(3) zeros(3,1)]);
        DotMap = reshape(max(0,sum(-reshape(Ncam,[480*640 3])' .* raycastingDirectionW,1)),[480 640]);
        imagesc(DotMap);
        colormap('gray'); axis equal; axis tight
        title(sprintf('Frame %d: Input Phong',frameID));
        axis off
    end
    

    if frameID==1
        camRtC2W = [eye(3) [0;0;0]];
    else
        MatchPairs{frameID-1} =  align2view(1,IMGcam1,XYZcam1,frameID,IMGcam,XYZcam);
        camRtC2W = MatchPairs{frameID-1}.Rt;
        
        if size(MatchPairs{frameID-1}.matches,2)<5
            disp('SIFT matching failed, ignoring this frame');
            continue;
        end
    end
    
    cameraRtC2W(:,:,frameID) = camRtC2W;

    
    %% update TSDF
    disp('update TSDF...');
    %tic
    updateTSDF(camRtC2W);
    %toc

    
       
    
    
    %{
    %% visualizing the voxel
    subplot(3,4,10)
    for i=1:voxel.size_grid(3)
        if min(min(min(tsdf_value(:,:,i)))) ~= max(max(max(tsdf_value(:,:,i))))
            imagesc(tsdf_weight(:,:,i)'); axis equal; axis tight; xlabel('x'); ylabel('y');
            title(['frame ' num2str(i) ' = depth ' num2str((i-1)*voxel.unit+voxel.range(3,1)) ' meter']);
            pause(0.05);
        end
    end

    subplot(3,4,10)
    for i=1:voxel.size_grid(3)
        if min(min(min(tsdf_value(:,:,i)))) ~= max(max(max(tsdf_value(:,:,i))))
            imagesc(tsdf_value(:,:,i)'); axis equal; axis tight; xlabel('x'); ylabel('y');
            title(['frame ' num2str(i) ' = depth ' num2str((i-1)*voxel.unit+voxel.range(3,1)) ' meter']);
            pause(0.05);
        end
    end
    %}
    
    

    
    %% ray casting for the result
    disp('ray casting');
    tic
    % ray casting result is in the world coordinate
    [VMap,NMap,tMap,CMap] = raycastingTSDFvectorized([eye(3) [0;0;0]], [0.4 8]);
    %[VMap,NMap,tMap] = raycastingTSDFdump(camRtC2WrayCasting, [0.4 8]);
    toc

    newDepth = reshape(VMap(3,:),480,640);
    
    
    if toVisualize
        subplot(3,4,5)
        imagesc(newDepth,dispclim); axis equal; axis tight; axis off
        title(sprintf('Fused Depth',frameID));
    end
    
    VMap = reshape(double(VMap'),480,640,3);
    VMap(:,:,4) = ~isnan(VMap(:,:,1));
    NMap = vertex2normal(VMap);
    % normalize normal map
    %NMap = NMap ./ repmat(sqrt(sum(NMap.^2,1)),3,1);    
    if toVisualize
        subplot(3,4,6)
        imagesc((NMap+1)/2); axis equal; axis tight; axis off
        title(sprintf('Fused Noraml',frameID));
    end
    
    if toVisualize
        subplot(3,4,7)
        raycastingDirectionW = transformRTdir(raycastingDirectionC,[eye(3) zeros(3,1)]);
        DotMap = reshape(max(0,sum(-reshape(NMap,[480*640 3])' .* raycastingDirectionW,1)),[480 640]);
        imagesc(DotMap);
        colormap('gray'); axis equal; axis tight; axis off
        title(sprintf('Fused Phong',frameID));
    end

    if toVisualize
        subplot(3,4,12)
        imagesc(abs(newDepth - XYZcam1(:,:,3)),dispclim); axis equal; axis tight; axis off
        title(sprintf('Difference of Depth',frameID));
        
        drawnow;
    end
    
    %{
    
    subplot(3,4,6)
    imagesc(min(1,max(0,(reshape(NMap',[480 640 3])+1)/2))); axis equal; axis tight
    title(sprintf('Frame %d: rayCasting Normal Map',frameID));
    drawnow;
    
    %figure
    %visNMap = reshape(NMap',[480 640 3]);
    %out = visualizeNormals(-visNMap);
    %imagesc(out)
    %title('rayCasting Normal Map');
    
    
    subplot(3,4,7)
    raycastingDirectionW = transformRTdir(raycastingDirectionC,camRtC2W);
    DotMap = reshape(max(0,sum(-NMap .* raycastingDirectionW,1)),[480 640]);
    imagesc(DotMap);
    colormap('gray'); axis equal; axis tight
    title(sprintf('Frame %d: phong shading',frameID));
    drawnow;
    
    if ~isempty(tsdf_color)
        subplot(3,4,8)
        imagesc(reshape(CMap',[480,640,3])/255);  axis equal; axis tight; 
        drawnow;
        title(sprintf('Frame %d: ray casting color',frameID));
    end
    
    %}
            
    
    %subplot(3,4,9)
    %imagesc(reshape(tMap,480,640)); axis equal; axis tight
    %title(sprintf('Frame %d: rayCasting tMap',frameID));
    %drawnow;
    
    

end


end

%% IO functions

function values = readValuesFromTxt(filename)
try
    values = textscan(urlread(filename),'%f');
catch
    fid = fopen(filename,'r');
    values = textscan(fid,'%f');
    fclose(fid);
end
values = values{1};
end

function XYZcamera = depth2XYZcamera(K, depth)
[x,y] = meshgrid(1:640, 1:480);
XYZcamera(:,:,1) = (x-K(1,3)).*depth/K(1,1);
XYZcamera(:,:,2) = (y-K(2,3)).*depth/K(2,2);
XYZcamera(:,:,3) = depth;
XYZcamera(:,:,4) = depth~=0;
end


function depth = depthRead(filename)
depth = imread(filename);
depth = bitor(bitshift(depth,-3), bitshift(depth,16-3));
depth = single(depth)/1000;
end
%{
    % test to make sure it is correct
    for i=0:65535
        depth = uint16(i);
        code =bitor(bitshift(depth,3),bitshift(depth,3-16));
        recoverDepth = bitor(bitshift(code,-3), bitshift(code,16-3));
        if (depth~=recoverDepth)
            fprintf('error + %d\n',i);
        end
    end
%}

function image = imageRead(filename)
image = imread(filename);
end


function files = dirSmart(page, tag)
[files, status] = urldir(page, tag);
if status == 0
    files = dir(fullfile(page, ['*.' tag]));
end
end

function [files, status] = urldir(page, tag)
if nargin == 1
    tag = '/';
else
    tag = lower(tag);
    if strcmp(tag, 'dir')
        tag = '/';
    end
    if strcmp(tag, 'img')
        tag = 'jpg';
    end
end
nl = length(tag);
nfiles = 0;
files = [];

% Read page
page = strrep(page, '\', '/');
[webpage, status] = urlread(page);

if status
    % Parse page
    j1 = findstr(lower(webpage), '<a href="');
    j2 = findstr(lower(webpage), '</a>');
    Nelements = length(j1);
    if Nelements>0
        for f = 1:Nelements
            % get HREF element
            chain = webpage(j1(f):j2(f));
            jc = findstr(lower(chain), '">');
            chain = deblank(chain(10:jc(1)-1));
            
            % check if it is the right type
            if length(chain)>length(tag)-1
                if strcmp(chain(end-nl+1:end), tag)
                    nfiles = nfiles+1;
                    chain = strrep(chain, '%20', ' '); % replace space character
                    files(nfiles).name = chain;
                    files(nfiles).bytes = 1;
                end
            end
        end
    end
end
end
