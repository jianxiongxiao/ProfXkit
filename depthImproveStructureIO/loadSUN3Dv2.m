function data = loadSUN3Dv2(sequenceName, frameIDs)

if ~exist('sequenceName','var')
    sequenceName = '2014-04-29_14-39-49_094959634447';
end


SUN3Dpath = '/n/fs/sun3d/sun3dv2/';

%{
fileID = fopen(fullfile(SUN3Dpath,sequenceName,'image/time.dat'));
imageTimestamp = fread(fileID,'int64');
fclose(fileID);
data.image = VideoReader(fullfile(SUN3Dpath,sequenceName,'image/image.mp4'));  
%}

imageFiles = dirSmart(fullfile(SUN3Dpath,sequenceName,'image/'),'jpg');
imageFrameID = zeros(1,length(imageFiles));
imageTimestamp = zeros(1,length(imageFiles));
for i=1:length(imageFiles)
    id_time = sscanf(imageFiles(i).name, '%d-%ld.jpg');
    imageFrameID(i) = id_time(1);
    imageTimestamp(i) = id_time(2);
    
    data.imageAll{i}= fullfile(fullfile(SUN3Dpath,sequenceName,'image',imageFiles(i).name));
end


depthFiles = dirSmart(fullfile(SUN3Dpath,sequenceName,'depth/'),'tif');
irFiles = dirSmart(fullfile(SUN3Dpath,sequenceName,'ir/'),'tif');

depthFrameID = zeros(1,length(depthFiles));
depthTimestamp = zeros(1,length(depthFiles));
for i=1:length(depthFiles)
    id_time = sscanf(depthFiles(i).name, '%d-%ld.tif');
    depthFrameID(i) = id_time(1);
    depthTimestamp(i) = id_time(2);
    
    data.depthAll{i}= fullfile(fullfile(SUN3Dpath,sequenceName,'depth',depthFiles(i).name));
end

irFrameID = zeros(1,length(irFiles));
irTimestamp = zeros(1,length(irFiles));
for i=1:length(irFiles)
    id_time = sscanf(irFiles(i).name, '%d-%ld.tif');
    irFrameID(i) = id_time(1);
    irTimestamp(i) = id_time(2);
    
    data.irAll{i}= fullfile(fullfile(SUN3Dpath,sequenceName,'ir',irFiles(i).name));
end

data.imageTimestamp = imageTimestamp;
data.depthTimestamp = depthTimestamp;

data.imageTotalFrames = length(data.imageTimestamp);
data.depthTotalFrames = length(data.depthTimestamp);

% synchronize: find a depth for each image
frameCount = length(imageTimestamp);
IDimage2depth = zeros(1,frameCount);
for i=1:frameCount
    [~, IDimage2depth(i)]=min(abs(double(depthTimestamp)-double(imageTimestamp(i))));
end

if ~exist('frameIDs','var') || isempty(frameIDs)
    frameIDs = 1:frameCount;
end

data.sequenceName = sequenceName;

cnt = 0;
for frameID=frameIDs
    cnt = cnt + 1;
    data.depth{cnt} = fullfile(fullfile(SUN3Dpath,sequenceName,'depth',depthFiles(IDimage2depth(frameID)).name));
    data.ir{cnt} = fullfile(fullfile(SUN3Dpath,sequenceName,'ir',irFiles(IDimage2depth(frameID)).name));
end


kinectID = strsplit(sequenceName,'_');
kinectID = kinectID{end};

data.camera = load(fullfile(SUN3Dpath,'intrinsics',[kinectID '.mat']));


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

function XYZcamera = depth2XYZcamera(K, depth)
    sz = size(depth);
    [x,y] = meshgrid(1:sz(2), 1:sz(1));
    XYZcamera(:,:,1) = (x-K(1,3)).*depth/K(1,1);
    XYZcamera(:,:,2) = (y-K(2,3)).*depth/K(2,2);
    XYZcamera(:,:,3) = depth;
    XYZcamera(:,:,4) = depth~=0;
end
