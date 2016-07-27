% Load data taken from Structure IO
function data = loadStructureIOdata(directory, frameIDs)

% Get image file list
imageFiles  = dir(fullfile(directory, 'color', '*.jpg'));
depthFiles = dir(fullfile(directory, 'depth', '*.png'));

% Set default frames to go through
if length(frameIDs) == 0
    frameIDs = 1:length(imageFiles);
end

% Loop through all image files to get corresponding image and depth names
count = 0;
data.depthTimestamp = zeros(1,length(depthFiles));
data.imageTimestamp = zeros(1,length(imageFiles));
for frameID = frameIDs
    count = count + 1;
    timestr = regexp(imageFiles(frameID).name,'\d+T\d+\.\d+\.\d+\.\d+-','match');
    timeArr = sscanf(timestr{1}, '%dT%d.%d.%d.%d-');
    data.imageTimestamp(frameID) = timeArr(1)*24*3600000 + timeArr(2)*3600000+timeArr(3)*60000+timeArr(4)*1000+timeArr(5);

    timestr = regexp(depthFiles(frameID).name,'\d+T\d+\.\d+\.\d+\.\d+-','match');
    timeArr = sscanf(timestr{1}, '%dT%d.%d.%d.%d-');
    data.depthTimestamp(frameID) = timeArr(1)*24*3600000 + timeArr(2)*3600000+timeArr(3)*60000+timeArr(4)*1000+timeArr(5);
    
    data.imageAll{count} = fullfile(fullfile(directory, 'color', imageFiles(frameID).name));
    data.depthAll{count} = fullfile(fullfile(directory, 'depth', depthFiles(frameID).name));
end

% Grab camera data
data.K = reshape(readValuesFromTxt(fullfile(directory, 'intrinsics.txt')), 3, 3)';
if exist(fullfile(directory, 'intrinsics_d2c.txt'),'file')
   depthCam = readValuesFromTxt(fullfile(directory, 'intrinsics_d2c.txt'));
   data.Kdepth = reshape(depthCam(1:9), 3, 3)';
   data.RT_d2c = reshape(depthCam(10:21), 4, 3)';
else
   data.image = data.imageAll;
   data.depth = data.depthAll;
   
   

end

