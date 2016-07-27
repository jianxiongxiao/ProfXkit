function camera_info = readCameraInfo(filename)

file_words=file2cellarray(filename);

camera_info = [];

for iline=1:length(file_words)
    switch(file_words{iline}{1})
        case('camera_number:')
            fprintf('camera_number: %s\n',file_words{iline}{2});
        case('camera_index:')
            camera_info(end+1).camera_index = str2num(file_words{iline}{2});
        case('')
        otherwise
            value = str2double(file_words{iline}{2});
            if isnan(value)
                value = file_words{iline}{2};
            end
            camera_info(end).(file_words{iline}{1}(1:end-1)) = value;
    end
end
