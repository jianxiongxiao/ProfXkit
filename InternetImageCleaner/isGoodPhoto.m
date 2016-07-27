function [result,croppedImage] = isGoodPhoto(img)

minWidth = 480;
minHeight = 480;

%minWidth = 128;
%minHeight = 128;


croppedImage = [];

if isa(img,'char')
    img = imread(img);
end

if isa(img,'logical')
    result = 'binary';
    return;
end

if ndims(img)>3
    result = 'animation';
    return;    
end

if size(img,1)<minHeight || size(img,2)<minWidth
    result = 'too small';
    return;
end


persistent emptyFlickrGIF;
persistent emptyFlickrPNG;
if isempty(emptyFlickrGIF) 
    [emptyFlickrGIF,map]= imread('emptyFlickr.gif');
    if ~isempty( map )
        emptyFlickrGIF = ind2rgb( emptyFlickrGIF, map );
    end
end
if isempty(emptyFlickrPNG) 
    emptyFlickrPNG = imread('emptyFlickr.png');
end

% check if it is flickr empty image
imgT = imresize(img,[size(emptyFlickrGIF,1), size(emptyFlickrGIF,2)]);
if size(imgT,3)==1
    diff= sum(reshape(abs(im2double(imgT)-rgb2gray(emptyFlickrGIF)),1,[]));
else
    diff= sum(reshape(abs(im2double(imgT)-emptyFlickrGIF),1,[]));
end
if diff<50
    result = 'flickr empty';
    return;
end


imgT = imresize(img,[size(emptyFlickrPNG,1), size(emptyFlickrPNG,2)]);
if size(imgT,3)==1
    diff= sum(reshape(abs(imgT-rgb2gray(emptyFlickrPNG)),1,[]));
else
    diff= sum(reshape(abs(imgT-emptyFlickrPNG),1,[]));
end
if diff<50
    result = 'flickr empty';
    return;
end

% check if it is line drawing
if size(img,3)==1
    h = imhist(img);
    if sum(h(240:end))/sum(h) > 0.5
        result = 'too white';
        return;
    elseif sum(h(1:10))/sum(h) > 0.5
        result = 'too black';
        return;
    end
else
    h = imhist(img(:,:,1)) + imhist(img(:,:,2)) + imhist(img(:,:,3));
    if sum(h(240:end))/sum(h) > 0.6
        result = 'too white';
        return;
    elseif sum(h(1:10))/sum(h) > 0.8
        result = 'too black';
        return;
    end
end

imgG = img;

G = fspecial('gaussian',[5 5],2);
%# Filter it
imgG = imfilter(imgG,G,'symmetric','same');

if size(imgG,3)>1
    imgG = rgb2gray(imgG);
end

tto = edge(imgG,'canny');

if sum(tto(:))/numel(tto) < 0.01
    result = 'too pure';
    return;
end
   
%{
% check if it is line drawing
imgG = img;
if size(imgG,3)>1
    imgG = rgb2gray(imgG);
end
h = imhist(imgG);
if sum(h(240:end))/sum(h) > 0.5
    result = 'too white';
    return;
elseif sum(h(1:10))/sum(h) > 0.5
    result = 'too black';
    return;
else
    [~,ind]=max(h);
    if sum(h(max(1,ind-7):min(256,ind+7)))/sum(h) > 0.7
        result = 'too pure';
        return;
    end
end
%}

% maybe useful http://www.mathworks.com/matlabcentral/fileexchange/25354-cropmat


if size(img,3)==1
    ttWhite = img>252;
else
    ttWhite = img(:,:,1)>252 & img(:,:,2)>252 & img(:,:,3)>252;
end

if size(img,3)==1
    ttBlack = img<5;
else
    ttBlack = img(:,:,1)<5 & img(:,:,2)<5 & img(:,:,3)<5;
end

wWhite=sum(ttWhite,1) > size(tto,1)*0.7;
hWhite=sum(ttWhite,2) > size(tto,2)*0.7;
wBlack=sum(ttBlack,1) > size(tto,1)*0.7;
hBlack=sum(ttBlack,2) > size(tto,2)*0.7;

anyEdgeW = sum(tto,1) > size(tto,1)*0.01;
anyEdgeH = sum(tto,2) > size(tto,2)*0.01;

minW=find(anyEdgeW, 1 )-1+2;   maxW=size(imgG,2)-find(anyEdgeW, 1, 'last' );
minH=find(anyEdgeH, 1 )-1+2;   maxH=size(imgG,1)-find(anyEdgeH, 1, 'last' );


try
    if minW<3 || maxW<3
        minW = 0;
        maxW = 0;
    else
        wMargin = wWhite | wBlack;
        if ~(any(wMargin(1:minW)) && any(wMargin(end-maxW:end)))
            minW = 0;
            maxW = 0;
        end        
    end

    if minH<3 || maxH<3
        minH = 0;
        maxH = 0;
    else
        hMargin = hWhite | hBlack;
        if ~(any(hMargin(1:minH)) && any(hMargin(end-maxH:end)))
            minH = 0;
            maxH = 0;
        end
    end

    if minW>0 || maxW>0 || minH>0 || maxH>0
        croppedImage = img(minH+1:size(imgG,1)-maxH,minW+1:size(imgG,2)-maxW,:);
        result = 'crop';
        
        if size(croppedImage,1)<minHeight || size(croppedImage,2)<minWidth
            result = 'too small';
        end
        
        
        return;
    end
catch
end


%{

% automatic image cropping
% http://stackoverflow.com/questions/11121657/find-the-edges-of-image-and-crop-it-in-matlab
%# instead of "==" you can check for similarity within a tolerance
%tt=img(:,:,1)==img(:,:,2) & img(:,:,2) == img(:,:,3);

if size(img,3)==1
    tt = img>252;
else
    tt = img(:,:,1)>252 & img(:,:,2)>252 & img(:,:,3)>252;
end

%# invert tt so that it's 1 where there is signal
tt = ~tt;

%# clean up some of the smaller artifacts
tto = imopen(tt,strel('square',10));

%# get the areas and bounding box of the areas above threshold
%# as an additional criterion, you could also use excentricity

stats = regionprops(tto,'BoundingBox','Area');
if ~isempty(stats)
    area = cat(1,stats.Area);
    [~,maxAreaIdx] = max(area);
    bb = round(stats(maxAreaIdx).BoundingBox);
    
    
    %# note that regionprops switches x and y (it's a long story)
    croppedImage = img(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1,:);

    if size(croppedImage,1)<size(img,1)-5 || size(croppedImage,2)<size(img,2)-5
        result = 'crop';
        return;
    end
end

%% black 
if size(img,3)==1
    tt = img<5;
else
    tt = img(:,:,1)<5 & img(:,:,2)<5 & img(:,:,3)<5;
end

%# invert tt so that it's 1 where there is signal
tt = ~tt;

%# clean up some of the smaller artifacts
tto = imopen(tt,strel('square',10));

%# get the areas and bounding box of the areas above threshold
%# as an additional criterion, you could also use excentricity

stats = regionprops(tto,'BoundingBox','Area');
if ~isempty(stats)
    area = cat(1,stats.Area);
    [~,maxAreaIdx] = max(area);
    bb = round(stats(maxAreaIdx).BoundingBox);
    
    %# note that regionprops switches x and y (it's a long story)
    croppedImage = img(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1,:);
    
    if size(croppedImage,1)<size(img,1)-5 || size(croppedImage,2)<size(img,2)-5
        result = 'crop';
        return;
    end
end

%}


result = 'good';
return;


