% this function will read a Bing download xml file and covert it
% into mysql batch command file

function outObj = readFlickrObj(inFname, outObj, topic_mid, keywords)


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
           '"mid": "' strrep(strrep(strrep(topic_mid,'\','\\'),'"','\"'),'''','\''') '", ' ...
           '"engine": "' 'flickr' '", ' ...
           '"url": "' urlEscape '", ' ...
           '"title": "' strrep(strrep(strrep(title,'\','\\'),'"','\"'),'''','\''') '"}'];   
   
   cnt = size(outObj,1);
   cnt = cnt + 1;
   outObj{cnt,1} = urlEscape;
   outObj{cnt,2} = info;
   outObj{cnt,3} = 'flickr';
end
