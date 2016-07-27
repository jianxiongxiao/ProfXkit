addpath /n/fs/vision/www/pvt/

latexFname = '/Users/xj/Documents/museumIJCV/museumCSG/ijcv.tex';
oriPath = '/Users/xj/Documents/museumIJCV/museumCSG/all';
newPath = '/Users/xj/Documents/museumIJCV/museumCSG/';

% this script parse a latex file and copy all figures into a new location
% this is usually used to get a clean version for submitting latex files
% to places like IJCV or ECCV that requires the latex file for final
% submission

str = file2string(latexFname);

pos = strfind(str,'\includegraphics[');

newline = sprintf('\n');

images = {};

for i=1:length(pos)
    ps = strfind(str(pos(i):end),'{');  ps = ps(1);
    pe = strfind(str(pos(i):end),'}');  pe = pe(1);
    
    nlp = strfind(str(1:pos(i)),newline);
    if isempty(nlp)
        nlp = 0;
    else
        nlp = nlp(end);
    end
    
    cmp = strfind(str(1:pos(i)),'%');
    if isempty(cmp)
        cmp = 0;
    else
        cmp = cmp(end);
    end
    
    if nlp>=cmp
        images{end+1} = str(pos(i)+ps:pos(i)+pe-2);
    end
end


for i=1:length(images)
    newF = fullfile(newPath,images{i});
    if ~exist(fileparts(newF),'dir')
        mkdir(fileparts(newF));
    end
    copyfile(fullfile(oriPath,images{i}),newF);
end
