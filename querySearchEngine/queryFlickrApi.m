function result = queryFlickrApi(original_keywords)

% example usage:  result = queryFlickrApi();

% information: see flickr api page: https://www.flickr.com/services/api/
% https://www.flickr.com/services/api/explore/flickr.photos.search

if ~exist('original_keywords','var')
    original_keywords = 'living room';
end

apiURL = 'http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=d10c081d41108144231911c96fcfe4c9&text=%s&page=%d&per_page=500';

%urlPhoto = 'http://farm%s.static.flickr.com/%s/%s_%s_b.jpg';
%sprintf(urlPhoto,farm_id,server_id,photo_id,secret_id);

query = urlencode(original_keywords);
query = regexprep(query,'%E2%80%8B',''); %<- strange bug


result = [];

page = 1;
pageCnt = 1;
while true
    link = sprintf(apiURL,query,page);
    strXML = urlread(link);
    
    if page==1
        str = strXML;
        pos = findstr(str,'pages="');
        if isempty(pos)
            break;
        else
            str = str(pos(1)+length('pages="'):end);
            pos = findstr(str,'"');
            str = str(1:pos(1)-1);
            pageCnt = str2num(str);
            if pageCnt==0
                break;
            end
            %if pageCnt > 200 && (length(findstr(original_keywords,' '))+1)==1
            %    pageCnt = 11;
            %end
            % http://www.flickr.com/groups/api/discuss/72157600679839291/
            % you cannot get more than 5k images from flickr
            if pageCnt >11
                pageCnt = 11;
            end
        end
    end
    
    resultNow = parseFlickr(strXML, original_keywords);
    result = [result; resultNow];
    
    %{
    fname = [tempname '.xml'];
    fp = fopen(fname,'w');
    fprintf(fp,'%s',strXML);
    fclose(fp);
    outObj = readFlickrObj(fname, original_keywords);
    delete(fname);
    %}
    
    if page >=pageCnt
        break;
    end
    page = page+1;
end

function result = parseFlickr(strXML, keywords)

    ids = regexp(strXML,'(<photo id=")[^"]+(")','match');
    owners = regexp(strXML,'(owner=")[^"]+(")','match');
    secrets = regexp(strXML,'(secret=")[^"]+(")','match');
    servers = regexp(strXML,'(server=")[^"]+(")','match');
    farms = regexp(strXML,'(farm=")[^"]+(")','match');
    titles = regexp(strXML,'(title=")[^"]*(")','match');
    %ispublic = regexp(strXML,'(ispublic=")[^"]+(")','match');
    %isfriend = regexp(strXML,'(isfriend=")[^"]+(")','match');
    %isfamily = regexp(strXML,'(isfamily=")[^"]+(")','match');

    urlPhoto = 'http://farm%s.static.flickr.com/%s/%s_%s_b.jpg';
    result = cell(length(ids),2);

    for i=1:length(ids)
        id = regexp(ids{i},'"','split'); id = id{2};
        owner = regexp(owners{i},'"','split'); owner = owner{2};
        secret = regexp(secrets{i},'"','split'); secret = secret{2};
        server = regexp(servers{i},'"','split'); server = server{2};
        farm = regexp(farms{i},'"','split'); farm = farm{2};
        title = regexp(titles{i},'"','split'); title = title{2};

        url = sprintf(urlPhoto,farm,server,id,secret);
        info = [ '{'  ...
            '"keywrods": "' strrep(strrep(strrep(keywords,'\','\\'),'"','\"'),'''','\''') '", ' ...
            '"url": "' url '", ' ...
            '"id": "' id '", ' ...
            '"owner": "' owner '", ' ...
            '"secret": "' secret '", ' ...
            '"server": "' server '", ' ...
            '"farm": "' farm '", ' ...
            '"title": "' title '" }'];
        result{i,1} = info;
        result{i,2} = url;
    end


%{
function download(url, fname)

downloadTemplate = 'wget --tries=2 --timeout=5 "%s" --user-agent="Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6" -O "%s"';
cmd = sprintf(downloadTemplate, url, fname);
system(cmd);
%}
%{
function fileStr = file2string(fname)
    fileStr = '';
    fid = fopen(fname,'r');
    tline = fgetl(fid);
    while ischar(tline)
        fileStr = [fileStr sprintf('\n') tline];
        tline = fgetl(fid);
    end
    fclose(fid);

%}

%{
function outObj = readFlickrObj(inFname, keywords)


urlPhoto = 'http://farm%s.static.flickr.com/%s/%s_%s_b.jpg';



xDoc = xmlread(inFname);
allImages = xDoc.getElementsByTagName('photo');
for k = 0:allImages.getLength-1
   thisImage = allImages.item(k);
   id = char(thisImage.getAttribute('id'));
   owner = char(thisImage.getAttribute('owner'));
   secret = char(thisImage.getAttribute('secret'));
   server = char(thisImage.getAttribute('server'));
   farm = char(thisImage.getAttribute('farm'));
   title = char(thisImage.getAttribute('title'));
   
   
   url = sprintf(urlPhoto,farm,server,id,secret);
   urlEscape = strrep(strrep(url,'\','\\'),'''','\''');

   info = ['{"id": "' strrep(strrep(strrep(id,'\','\\'),'"','\"'),'''','\''') '", ' ...
           '"owner": "' strrep(strrep(strrep(owner,'\','\\'),'"','\"'),'''','\''') '", ' ...
           '"secret": "' strrep(strrep(strrep(secret,'\','\\'),'"','\"'),'''','\''') '", ' ...
           '"server": "' strrep(strrep(strrep(server,'\','\\'),'"','\"'),'''','\''') '", ' ...
           '"farm": "' strrep(strrep(strrep(farm,'\','\\'),'"','\"'),'''','\''') '", ' ...
           '"keywrods": "' strrep(strrep(strrep(keywords,'\','\\'),'"','\"'),'''','\''') '", ' ...
           '"engine": "' 'flickr' '", ' ...
           '"url": "' urlEscape '", ' ...
           '"title": "' strrep(strrep(strrep(title,'\','\\'),'"','\"'),'''','\''') '"}'];   
   
   cnt = size(outObj,1);
   cnt = cnt + 1;
   outObj{cnt,1} = urlEscape;
   outObj{cnt,2} = info;
   outObj{cnt,3} = 'flickr';
end

%}