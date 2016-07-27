% find all images under the path fullfile(rootPath,category)
% Written by Jianxiong Xiao @ 20130812

if ~exist('rootPath','var')
    rootPath = '/data/vision/torralba/gigaSUN/imageTurk/';
end
if ~exist('category','var')
    category = 'o/office_cubicles';
    %category = 'o/office_cubicles/0';
end

% parameters
numTestPerBatch  = 100;
% truth
numTruthPerBatch = 5;
numPositiveTruthPerBatch = 5;

% load truth
load truth.mat

URLheader = 'http://gigasun.csail.mit.edu/turk/';
URLheaderLength = length('/data/vision/torralba/gigaSUN/imageTurk/')+1;
URLheaderTruth = 1;
questionDisplay = 'office cubicles';
questionReal = category;

positiveTest = [];
for i=1:length(truth)
    if strcmp(truth{i}.truth,questionReal)
        positiveTest(end+1) = i;
    end
end

if isempty(positiveTest)
    fprintf('Warning: %s has no positive truth!\n', questionReal);
end

folders = regexp(genpath(fullfile(rootPath,category)), pathsep, 'split');
folders = folders(1:end-1);

numTotal = 0;
for f=1:length(folders)
    files = dir(folders{f});
    for i=1:length(files)
        if ~files(i).isdir
            numTotal = numTotal + 1;
            images{numTotal} = fullfile(folders{f},files(i).name);
        end
    end
end

numBatch = max(1,round(numTotal/numTestPerBatch));

try
    mkdir(fileparts([questionReal '.csv']));
catch
end
fp = fopen([questionReal '.csv'],'w');
fprintf(fp,'question,data\n');

for b=1:numBatch
    startID = numTestPerBatch*(b-1)+1;
    if b==numBatch
        endID = length(images);
    else
        endID = numTestPerBatch*b;
    end
    testImages = images(startID:endID);
    % draw some truth   
    truthImages = [randsample(length(truth),numTruthPerBatch)];
    if ~isempty(positiveTest)
        truthImages = [truthImages; positiveTest(randsample(length(positiveTest),numPositiveTruthPerBatch,true))];
    end
    
    truthImages = truth(truthImages);
    
    allImages = cell(1,0);
    for k=1:length(testImages)
        allImages{end+1} = ['{"image": "' URLheader testImages{k}(URLheaderLength:end) '"}'];
    end
    for k=1:length(truthImages)
        if strcmp(truthImages{k}.truth,questionReal)
            answer = 'true';
        else
            answer = 'false';
        end
        allImages{end+1} = ['{"image": "' truthImages{k}.image(URLheaderTruth:end) '", "truth": ' answer '}'];
    end
    allImages = allImages(randperm(length(allImages)));
    
    fprintf(fp,'%s,', questionDisplay);
    fprintf(fp,'"[');
    for k=1:length(allImages)-1
        fprintf(fp,'%s,',regexprep(allImages{k},'"','""'));
    end
    fprintf(fp,'%s',regexprep(allImages{end},'"','""'));
    fprintf(fp,']"');
    
    if b<numBatch
        fprintf(fp,'\n');
    end
end
fclose(fp);
