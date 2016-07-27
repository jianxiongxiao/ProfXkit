function queryFlickr(topic_name, topic_path)


apiURL = 'http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=d10c081d41108144231911c96fcfe4c9&text=%s&page=%d&per_page=500';

%urlPhoto = 'http://farm%s.static.flickr.com/%s/%s_%s_b.jpg';
%sprintf(urlPhoto,farm_id,server_id,photo_id,secret_id);

query = urlencode(topic_name);
query = regexprep(query,'%E2%80%8B',''); %<- strange bug

page = 1;
pageCnt = 1;
while true
    link = sprintf(apiURL,query,page);
    fname = fullfile(topic_path,sprintf('%.3d.xml', page));
    download(link, fname);
    if page==1
        str = file2string(fname);
        
        pos = findstr(str,'pages="');
        if isempty(pos)
            delete(fname);
            break;
        else
            str = str(pos(1)+length('pages="'):end);
            pos = findstr(str,'"');
            str = str(1:pos(1)-1);
            pageCnt = str2num(str);
            if pageCnt==0
                delete(fname);
                break;
            end
            %if pageCnt > 200 && (length(findstr(topic_name,' '))+1)==1
            %    pageCnt = 11;
            %end
            % http://www.flickr.com/groups/api/discuss/72157600679839291/
            % you cannot get more than 5k images from flickr
            if pageCnt >11
                pageCnt = 11;
            end
        end
    end
    
    if page >=pageCnt
        break;
    end
    page = page+1;
end

