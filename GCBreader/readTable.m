function [value,header] = readTable(filename)

fid = fopen(filename,'r');
header = fgetl(fid);

% a hack to fix google's bug
header = strrep(header,'position y','position_y');

header = strsplit(header,' ')';

value = fscanf(fid,'%f');

value = reshape(value,length(header),[]);

fclose(fid);
