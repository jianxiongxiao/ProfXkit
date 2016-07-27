function metadata = readMetaData(filename)

fid=fopen(filename,'r');
file_text=fread(fid, inf, 'uint8=>char')';
fclose(fid);
file_lines = regexp(file_text, '\n+', 'split');
file_words = regexp(file_lines, ':', 'split');

metadata = {};

for iline=1:length(file_words)
    switch(file_words{iline}{1})
        case('')
        otherwise
            value = str2num(file_words{iline}{2}(2:end));
            if isempty(value)
                value = file_words{iline}{2}(2:end);
            end
            metadata.(strrep(file_words{iline}{1},' ','_')) = value;
    end
end
