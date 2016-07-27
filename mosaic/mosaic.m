
imageRootPath = '/n/fs/vision/datasets/SUN397/';


%% get image list
disp('generating image list...');
folders = genpath(imageRootPath);
folders = regexp(folders,':','split');
folders = folders(1:end-1);
imageList = {};
for f=1:length(folders)
    imagefiles = dir(fullfile(folders{f},'*.jpg'));
    if ~isempty(imagefiles)
        for i=1:length(imagefiles)
            imageList{end+1} = fullfile(folders{f},imagefiles(i).name);
        end
    end
end


%% read image, crop, and resize
disp('reading and resizing images...');

tWidth =32;
tHeight=32;
imArray = uint8(zeros(tHeight,tWidth,3,length(imageList)));

for i=1:length(imageList)
    im = imread(imageList{i});
    w = size(im,2);
    h = size(im,1);
    ch = w/tWidth*tHeight;
    if ch<h
        srow = max(1,floor(h/2-ch/2));
        erow = srow + round(ch)-1;
        im = im(srow:erow,:,:);
    elseif ch>h
        cw = h/tHeight*tWidth;
        if cw<w
            scol = max(1,floor(w/2-cw/2));
            ecol = scol + round(cw)-1;
            im = im(:,scol:ecol,:);
        end
    end
    
    if size(im,3)==1
        im = im(:,:,[1 1 1]);
    end
    
    imArray(:,:,:,i) = imresize(im,[tHeight tWidth]);
    
    if mod(i,100)==1
        fprintf('%d/%d\n',i,length(imageList));
    end
end



save('sun397.mat','-v7.3');


%% 
% 
load sun397.mat
imArray = double(imArray)/255;

baseImage = 'base9.png';
baseImage = im2double(imread(baseImage));
baseImage = baseImage(:,:,1:3);
nH = floor(size(baseImage,1)/tHeight);
nW = floor(size(baseImage,2)/tWidth);
baseImage = baseImage(1:nH*tHeight,1:nW*tWidth,:);

nI = size(imArray,4);
usedVector = false(1,nI);

mosaicImage = zeros(nH*tHeight,nW*tWidth,3);

for y=randperm(nH)
    ey = y*tHeight;
    sy = ey-tHeight+1;
    for x=randperm(nW)
        ex = x*tWidth;
        sx = ex-tWidth+1;
        
        sourcePath = baseImage(sy:ey,sx:ex,:);
        
        diff = sum(sum(sum(abs(imArray - repmat(sourcePath,[1,1,1,nI])),1),2),3);
        diff = reshape(diff,1,[]) + usedVector .* 100000;
        
        [minVal,minIdx]= min(diff);
        
        usedVector(minIdx) = true;
        
        mosaicImage(sy:ey,sx:ex,:) = imArray(:,:,:,minIdx);
    end
end

imwrite(mosaicImage,'mosaic9.png');
imshow(mosaicImage);
