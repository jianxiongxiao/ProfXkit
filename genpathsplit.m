function folders = genpathsplit(path)

% genpath but return with well-organize results

folders = regexp(genpath(path), pathsep, 'split');
folders = folders(1:end-1);

