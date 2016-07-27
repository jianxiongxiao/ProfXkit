function files = genfiles(path,name)
% recurisviely look for files in a path
% example usage:
% files = genfiles('~/Downloads','*.jpg');

folders = genpathsplit(path);

files = [];

for folderID=1:length(folders)
    cfiles = dir(fullfile(folders{folderID},name));
    for fileID=1:length(cfiles)
        files{end+1} = fullfile(folders{folderID},cfiles(fileID).name);
    end
end
