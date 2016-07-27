clear
close all
clc


zoom = 5;

seed_panoid = 'AgJryEreGs4cfOUZQJg9Uw';


download_number = 1; % number of panorama you want to download


outfolder = seed_panoid; %'data';
if ~exist(outfolder,'dir')
    mkdir(outfolder)
end



cnt = 0;

panoidAll = {seed_panoid};
downloadAll = false(1);
neighborAll = true(1);


while cnt<download_number
    %for i=length(downloadAll):-1:1 % dfs
    for i=1:length(downloadAll) % bfs
        if downloadAll(i)==false
            break;
        end
    end
    if downloadAll(i)==true
        break;
    end
    cnt = cnt + 1;
    panoids = downloadPano(panoidAll{i}, outfolder, zoom);
   
    figure(1)
    subplot(2,1,1);
    imshow(imread(fullfile(panoidAll{i},[panoidAll{i} '.jpg'])));
    title('image');
    subplot(2,1,2);
    imagesc(imread(fullfile(panoidAll{i},[panoidAll{i} '.png'])));
    axis equal;
    axis tight;
    axis off;
    title('depth');
    
    
    downloadAll(i)=true;
    
    mainIdx = i;
    
    for i=1:length(panoids)
        Idx = find(ismember(panoidAll,panoids{i})==1);
        if isempty(Idx) && length(panoidAll)<download_number
            panoidAll{end+1} = panoids{i};
            downloadAll(end+1) = false;
            Idx = length(downloadAll);
        end
        if ~isempty(Idx)
            neighborAll(Idx,Idx) = true;
            neighborAll(mainIdx,Idx) = true;
            neighborAll(Idx,mainIdx) = true;
        end
    end
end

figure(2)
imagesc(neighborAll);
axis equal
axis tight
set(gca,'YTick',[1:length(panoidAll)])
set(gca,'YTickLabel',panoidAll)
title('connectivity graph')
