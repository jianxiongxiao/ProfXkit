imageRootPath = 'png/';
newRootPath = 'jpg/';


folders = genpath(imageRootPath);
folders = regexp(folders,':','split');
folders = folders(1:end-1);
imageList = {};
for f=1:length(folders)
    imagefiles = dir(fullfile(folders{f},'*.png'));
    if ~isempty(imagefiles)
        
        new_folder=fullfile(newRootPath, folders{f});
        if ~exist(new_folder,'dir')
            mkdir(new_folder);
        end
        
        for i=1:length(imagefiles)
            imageList{end+1} = fullfile(folders{f},imagefiles(i).name);
            
            % png to jpg
            im = imread(imageList{end});
            imwrite(im, fullfile(new_folder, [imagefiles(i).name 'jpg']));
        end
    end
end

