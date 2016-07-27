function [pathstr,name,ext] = filepartsVector(filename) 

pathstr = [];
name = [];
ext = [];
for i=1:length(filename)
    [pathstr{i},name{i},ext{i}] = fileparts(filename{i});
end
