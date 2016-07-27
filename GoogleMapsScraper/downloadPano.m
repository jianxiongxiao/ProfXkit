function panoids = downloadPano(panoid, outfolder,zoom)

% panoid = '6KVe7UierNYlLbhcbOyvhw';

if zoom==5
    pano =  uint8(zeros(512*(12+1),512*(25+1),3));
    for x=0:25
        for y=0:12
            im = imresize(imread(sprintf('http://maps.google.com/cbk?output=tile&zoom=5&x=%d&y=%d&cb_client=maps_sv&fover=2&onerr=3&renderer=spherical&v=4&panoid=%s',x,y,panoid)),[512 512]);
            pano(512*y+(1:512),512*x+(1:512),:) = im;
        end
    end
elseif zoom==4
    pano =  uint8(zeros(512*(6+1),512*(11+1),3));
    for x=0:11
        for y=0:6
            im = imresize(imread(sprintf('http://maps.google.com/cbk?output=tile&zoom=4&x=%d&y=%d&cb_client=maps_sv&fover=2&onerr=3&renderer=spherical&v=4&panoid=%s',x,y,panoid)),[512 512]);
            pano(512*y+(1:512),512*x+(1:512),:) = im;
        end
    end    
    
end

imwrite(pano,fullfile(outfolder,sprintf('%s.jpg',panoid)),'Quality',100);

%imshow(imresize(pano,[13 26]*32))

url = sprintf('http://maps.google.com/cbk?output=xml&cb_client=maps_sv&hl=en&dm=1&pm=1&ph=1&renderer=cubic,spherical&v=4&panoid=%s',panoid);
fname = fullfile(outfolder,sprintf('%s.xml',panoid));
cmdLine     = 'wget "%s" -t 2 -T 5 -O %s --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6"';
system(sprintf(cmdLine, url, fname));


str = file2string(fname);

pos = findstr(str,'pano_id=');
panoids = {};
cnt = 0;

for i=1:length(pos)
    panoid_new = str((pos(i)+9):(pos(i)+8+length(panoid)));
    if ~strcmp(panoid_new,panoid)
        cnt = cnt+1;
        panoids{cnt} = panoid_new;
    end
end

system(sprintf('./decode_depthmap %s %s.txt', fname, fullfile(outfolder,panoid)));


depth = textread(fullfile(outfolder,[panoid '.txt']),'%f');
depth = reshape(depth,512*3,256);
depth_x = depth(1:3:end,:)';
depth_y = depth(2:3:end,:)';
depth_z = depth(3:3:end,:)';
depth = cat(3,depth_x,depth_y,depth_z);
depth = sqrt(sum(depth.^2,3));
imwrite(depth/100,fullfile(outfolder,[panoid '.png']));
