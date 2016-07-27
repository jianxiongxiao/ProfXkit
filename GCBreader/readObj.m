function groups = readObj(filename)
% only for Google Street View data

file_words = file2cellarray(filename);

groups = [];
for iline=1:length(file_words)    
    switch(file_words{iline}{1})
        case('g') % vertices
            groups(end+1).v = [];
            values = sscanf(file_words{iline}{2},'seg_%d_scanline_%d');
            groups(end).seg = values(1);
            groups(end).scanline = values(2);
        case('v') % vertices
            groups(end).v = [groups(end).v str2double(file_words{iline}(2:4))'];
    end
end
