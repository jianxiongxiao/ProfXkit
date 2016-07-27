function [images, image2keep, image2delete]=duplicateRemoval(rootPath,category)
% find all duplicates under the path fullfile(rootPath,category)
% and DELETE all the duplicated images!!! (file deletion will happen!!!)

% Written by Jianxiong Xiao @ 20130812

if ~exist('rootPath','var')
    rootPath = '/data/vision/torralba/gigaSUN/imageGood/';
end
if ~exist('category','var')
    %category = 'o/office_cubicles/';
    category = 'o/office_cubicles';
end

% parameters
threshold_1st = 0.0005; % threshold for the first pca components
threshold_gist = 0.02;  % threshold for the gist square distance

% parameters for gist
param.imageSize = [256 256]; % it works also with non-square images
param.orientationsPerScale = [8 8 8 8];
param.numberBlocks = 4;
param.fc_prefilt = 4;
param.boundaryExtension = 32; % number of pixels to pad
param.G = createGabor(param.orientationsPerScale, param.imageSize+2*param.boundaryExtension);

folders = regexp(genpath(fullfile(rootPath,category)), pathsep, 'split');
folders = folders(1:end-1);


cnt = 0;
for f=1:length(folders)
    files = dir(folders{f});
    for i=1:length(files)
        if ~files(i).isdir
            cnt = cnt + 1;
            images{cnt} = fullfile(folders{f},files(i).name);
        end
    end
end

if matlabpool('size')==0
    try
        matlabpool
    catch e
    end
end
fprintf('# CPU threads = %d\n',matlabpool('size'));

% current implementation load all images into the memory
% it can be improved by loading individual images into the memory


fprintf('computing gist for %d images',cnt);
tic
gistMatrix =single(zeros(cnt,512));
parfor i=1:cnt
    gistMatrix(i,:) = LMgist(imread(images{i}), '', param);
end
toc

try
    load('pca_result.mat');
catch e
    % training
    mu = mean(gistMatrix,1);
    
    fprintf('PCAing');
    tic
    coeff = princomp(bsxfun(@minus, gistMatrix,mu));
    toc
    cnt = length(images);
    save('pca_result.mat','mu','coeff','rootPath','category','cnt','-v7.3');    
end


% reproject

score_reproject = bsxfun(@minus, gistMatrix,mu)*coeff;
score_1st = score_reproject(:,1);

cnt = length(images);
time_complexity = zeros(1,cnt-1);
duplicates = cell(cnt-1,1);
parfor i=1:cnt-1
    candidates = find(abs(score_1st(i+1:end) - score_1st(i))<threshold_1st);
    time_complexity(i)=length(candidates);
    candidates = candidates + i;
    diff = sum(bsxfun(@minus, gistMatrix(candidates,:),gistMatrix(i,:)) .^ 2,2);
    candidates_subset = find(diff < threshold_gist);
    if isempty(candidates_subset)
        duplicates{i} = single(zeros(0,3));
    else
        duplicates{i} =[repmat(i,length(candidates_subset),1) candidates(candidates_subset) diff(candidates_subset)];
    end
end
fprintf('\nTime complexity = %f\n',mean(time_complexity));

duplicates = cell2mat(duplicates);
[~,ind] = sort(duplicates(:,3));
duplicates = duplicates(ind,:);


%save('debugThreshold.mat','duplicates','images','-v7.3');

duplicates = duplicates(duplicates(:,3)<threshold_gist,:);

%{
% visualization for duplicate pairs. duplicates, images
close all
for i=1:max(1,round(size(duplicates,1)/30)):size(duplicates,1)
    figure(i);
    subplot(1,2,1);
    imshow(imread(images{duplicates(i,1)}));
    title(duplicates(i,3));
    subplot(1,2,2);
    imshow(images{duplicates(i,2)});
end
%}

fprintf('connected components');
tic
G =  sparse(double(duplicates(:,1)), double(duplicates(:,2)),true,length(images),length(images));
[numOfComponents, componentID] = graphconncomp(G, 'Weak', true);
toc

% connected component
image2keep   = [];
image2delete = cell(0,0);
for i=1:numOfComponents
    ids = find(componentID==i);
    if length(ids)>1
        area = zeros(1,length(ids));
        for j=1:length(ids)
            im = imread(images{ids(j)});
            area(j) = size(im,1)*size(im,2);
        end
        [~,maxj] = max(area);
        image2keep = [image2keep ids(maxj)];
        image2delete{end+1} = ids( 1:length(ids) ~= maxj);
    end
end

% visualize for connected components
%{
for i=1:length(image2keep)
    figure(i)
    num = length(image2delete{i})+1;
    subplot(1,num,1);
    imshow(imread(images{image2keep(i)}));
    title(images{image2keep(i)})
    for j=1:num-1
        subplot(1,num,j+1);
        imshow(imread(images{image2delete{i}(j)}));        
        title(images{image2delete{i}(j)})
    end
end
%}

% delete the duplicated images
disp('Deleting images');
cntDeletedImages = 0;
for i=1:length(image2delete)
    cntDeletedImages = cntDeletedImages + length(image2delete{i});
    for j=1:length(image2delete{i})
        delete(images{image2delete{i}(j)});
        disp(images{image2delete{i}(j)});
    end
end

disp('Image-based duplicate removal is finished!');
fprintf('Removed %d images (from %d images to %d images)\n', cntDeletedImages, length(images), length(images)-cntDeletedImages);

end

%% gist computation functions from Antonio

function [gist, param] = LMgist(D, HOMEIMAGES, param, HOMEGIST)
%
% [gist, param] = LMgist(D, HOMEIMAGES, param);
% [gist, param] = LMgist(filename, HOMEIMAGES, param);
% [gist, param] = LMgist(filename, HOMEIMAGES, param, HOMEGIST);
%
% For a set of images:
% gist = LMgist(img, [], param);
%
% When calling LMgist with a fourth argument it will store the gists in a
% new folder structure mirroring the folder structure of the images. Then,
% when called again, if the gist files already exist, it will just read
% them without recomputing them:
%
%   [gist, param] = LMgist(filename, HOMEIMAGES, param, HOMEGIST);
%   [gist, param] = LMgist(D, HOMEIMAGES, param, HOMEGIST);
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Modeling the shape of the scene: a holistic representation of the spatial envelope
% Aude Oliva, Antonio Torralba
% International Journal of Computer Vision, Vol. 42(3): 145-175, 2001.

if nargin==4
    precomputed = 1;
    % get list of folders and create non-existing ones
    %listoffolders = {D(:).annotation.folder};

    %for i = 1:length(D);
    %    f{i} = D(i).annotation.folder;
    %end
    %[categories,b,class] = unique(f);
else
    precomputed = 0;
    HOMEGIST = '';
end

% select type of input
if isstruct(D)
    % [gist, param] = LMgist(D, HOMEIMAGES, param);
    Nscenes = length(D);
    typeD = 1;
end
if iscell(D)
    % [gist, param] = LMgist(filename, HOMEIMAGES, param);
    Nscenes = length(D);
    typeD = 2;
end
if isnumeric(D)
    % [gist, param] = LMgist(img, HOMEIMAGES, param);
    Nscenes = size(D,4);
    typeD = 3;
    if ~isfield(param, 'imageSize')
        param.imageSize = [size(D,1) size(D,2)];
    end
end
    
param.boundaryExtension = 32; % number of pixels to pad

if nargin<3
    % Default parameters
    param.imageSize = 128;
    param.orientationsPerScale = [8 8 8 8];
    param.numberBlocks = 4;
    param.fc_prefilt = 4;
    param.G = createGabor(param.orientationsPerScale, param.imageSize+2*param.boundaryExtension);
else
    if ~isfield(param, 'G')
        param.G = createGabor(param.orientationsPerScale, param.imageSize+2*param.boundaryExtension);
    end
end

% Precompute filter transfert functions (only need to do this once, unless
% image size is changes):
Nfeatures = size(param.G,3)*param.numberBlocks^2;


% Loop: Compute gist features for all scenes
gist = zeros([Nscenes Nfeatures], 'single');
for n = 1:Nscenes
    g = [];
    todo = 1;
    
    % if gist has already been computed, just read the file
    if precomputed==1
        filegist = fullfile(HOMEGIST, D(n).annotation.folder, [D(n).annotation.filename(1:end-4) '.mat']);
        if exist(filegist, 'file')
            load(filegist, 'g');
            todo = 0;
        end
    end
    
    % otherwise compute gist
    if todo==1
        if Nscenes>1 disp([n Nscenes]); end

        % load image
        try
            switch typeD
                case 1
                    img = LMimread(D, n, HOMEIMAGES);
                case 2
                    img = imread(fullfile(HOMEIMAGES, D{n}));
                case 3
                    img = D(:,:,:,n);
            end
        catch
            disp(D(n).annotation.folder)
            disp(D(n).annotation.filename)
            rethrow(lasterror)
        end
        
        % convert to gray scale
        img = single(mean(img,3));

        % resize and crop image to make it square
        img = imresizecrop(img, param.imageSize, 'bilinear');
        %img = imresize(img, param.imageSize, 'bilinear'); %jhhays

        % scale intensities to be in the range [0 255]
        img = img-min(img(:));
        %img = 255*img/max(img(:));
        img = 255*img/max(1,max(img(:)));
        
        if Nscenes>1
            imshow(uint8(img))
            title(n)
        end

        % prefiltering: local contrast scaling
        output    = prefilt(img, param.fc_prefilt);

        % get gist:
        g = gistGabor(output, param);
        
        % save gist if a HOMEGIST file is provided
        if precomputed
            mkdir(fullfile(HOMEGIST, D(n).annotation.folder))
            save (filegist, 'g')
        end
    end
    
    gist(n,:) = g;
    drawnow
end

end


function output = prefilt(img, fc)
% ima = prefilt(img, fc);
% fc  = 4 (default)
% 
% Input images are double in the range [0, 255];
% You can also input a block of images [ncols nrows 3 Nimages]
%
% For color images, normalization is done by dividing by the local
% luminance variance.

if nargin == 1
    fc = 4; % 4 cycles/image
end

w = 5;
s1 = fc/sqrt(log(2));

% Pad images to reduce boundary artifacts
img = log(img+1);
img = padarray(img, [w w], 'symmetric');
[sn, sm, c, N] = size(img);
n = max([sn sm]);
n = n + mod(n,2);
img = padarray(img, [n-sn n-sm], 'symmetric','post');

% Filter
[fx, fy] = meshgrid(-n/2:n/2-1);
gf = fftshift(exp(-(fx.^2+fy.^2)/(s1^2)));
gf = repmat(gf, [1 1 c N]);

% Whitening
output = img - real(ifft2(fft2(img).*gf));
clear img

% Local contrast normalization
localstd = repmat(sqrt(abs(ifft2(fft2(mean(output,3).^2).*gf(:,:,1,:)))), [1 1 c 1]); 
output = output./(.2+localstd);

% Crop output to have same size than the input
output = output(w+1:sn-w, w+1:sm-w,:,:);

end



function g = gistGabor(img, param)
% 
% Input:
%   img = input image (it can be a block: [nrows, ncols, c, Nimages])
%   param.w = number of windows (w*w)
%   param.G = precomputed transfer functions
%
% Output:
%   g: are the global features = [Nfeatures Nimages], 
%                    Nfeatures = w*w*Nfilters*c

img = single(img);

w = param.numberBlocks;
G = param.G;
be = param.boundaryExtension;

if ndims(img)==2
    c = 1; 
    N = 1;
    [nrows ncols c] = size(img);
end
if ndims(img)==3
    [nrows ncols c] = size(img);
    N = c;
end
if ndims(img)==4
    [nrows ncols c N] = size(img);
    img = reshape(img, [nrows ncols c*N]);
    N = c*N;
end

[ny nx Nfilters] = size(G);
W = w*w;
g = zeros([W*Nfilters N]);

% pad image
img = padarray(img, [be be], 'symmetric');

img = single(fft2(img)); 
k=0;
for n = 1:Nfilters
    ig = abs(ifft2(img.*repmat(G(:,:,n), [1 1 N]))); 
    ig = ig(be+1:ny-be, be+1:nx-be, :);
    
    v = downN(ig, w);
    g(k+1:k+W,:) = reshape(v, [W N]);
    k = k + W;
    drawnow
end

if c == 3
    % If the input was a color image, then reshape 'g' so that one column
    % is one images output:
    g = reshape(g, [size(g,1)*3 size(g,2)/3]);
end

end


function y=downN(x, N)
% 
% averaging over non-overlapping square image blocks
%
% Input
%   x = [nrows ncols nchanels]
% Output
%   y = [N N nchanels]

nx = fix(linspace(0,size(x,1),N+1));
ny = fix(linspace(0,size(x,2),N+1));
y  = zeros(N, N, size(x,3));
for xx=1:N
  for yy=1:N
    v=mean(mean(x(nx(xx)+1:nx(xx+1), ny(yy)+1:ny(yy+1),:),1),2);
    y(xx,yy,:)=v(:);
  end
end

end

function img = imresizecrop(img, M, METHOD)
%
% img = imresizecrop(img, M, METHOD);
%
% Output an image of size M(1) x M(2).

if nargin < 3
    METHOD = 'bilinear';
end

if length(M) == 1
    M = [M(1) M(1)];
end

scaling = max([M(1)/size(img,1) M(2)/size(img,2)]);

%scaling = M/min([size(img,1) size(img,2)]);

newsize = round([size(img,1) size(img,2)]*scaling);
img = imresize(img, newsize, METHOD);

[nr nc cc] = size(img);

sr = floor((nr-M(1))/2);
sc = floor((nc-M(2))/2);

img = img(sr+1:sr+M(1), sc+1:sc+M(2),:);

end


function G = createGabor(or, n)
%
% G = createGabor(numberOfOrientationsPerScale, n);
%
% Precomputes filter transfer functions. All computations are done on the
% Fourier domain. 
%
% If you call this function without output arguments it will show the
% tiling of the Fourier domain.
%
% Input
%     numberOfOrientationsPerScale = vector that contains the number of
%                                orientations at each scale (from HF to BF)
%     n = imagesize = [nrows ncols] 
%
% output
%     G = transfer functions for a jet of gabor filters


Nscales = length(or);
Nfilters = sum(or);

if length(n) == 1
    n = [n(1) n(1)];
end

l=0;
for i=1:Nscales
    for j=1:or(i)
        l=l+1;
        param(l,:)=[.35 .3/(1.85^(i-1)) 16*or(i)^2/32^2 pi/(or(i))*(j-1)];
    end
end

% Frequencies:
%[fx, fy] = meshgrid(-n/2:n/2-1);
[fx, fy] = meshgrid(-n(2)/2:n(2)/2-1, -n(1)/2:n(1)/2-1);
fr = fftshift(sqrt(fx.^2+fy.^2));
t = fftshift(angle(fx+sqrt(-1)*fy));

% Transfer functions:
G=zeros([n(1) n(2) Nfilters]);
for i=1:Nfilters
    tr=t+param(i,4); 
    tr=tr+2*pi*(tr<-pi)-2*pi*(tr>pi);

    G(:,:,i)=exp(-10*param(i,1)*(fr/n(2)/param(i,2)-1).^2-2*param(i,3)*pi*tr.^2);
end


if nargout == 0
    figure
    for i=1:Nfilters
        contour(fx, fy, fftshift(G(:,:,i)),[1 .7 .6],'r');
        hold on
    end
    axis('on')
    axis('equal')
    axis([-n(2)/2 n(2)/2 -n(1)/2 n(1)/2])
    axis('ij')
    xlabel('f_x (cycles per image)')
    ylabel('f_y (cycles per image)')
    grid on
end


end
