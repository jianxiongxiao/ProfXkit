function result = queryBingWeb(original_keywords)

% example usage:  result = queryBingWeb();

if ~exist('original_keywords','var')
    original_keywords = 'living room';
end

keywords = regexprep(original_keywords,' ','+');

chunk = 150;

url_template = 'http://www.bing.com/images/async?q=%s&async=content&first=%d&count=%d';

cnt = 0;

for first=1:chunk:1000
    url = sprintf(url_template,keywords,first,chunk);
    html = urlread(url);
    pos = strfind(html,'<div class="imgres">');
    html = html(pos+20:end-12);
    items = regexp(html, '</div>', 'split');
    items = items(1:end-1);
    for itemID=1:length(items)
        
        s = strfind(items{itemID},'m="{')+3;
        e = strfind(items{itemID},'}"');
        info = regexprep(items{itemID}(s:e),'&quot;','"');

        s = strfind(items{itemID},'t1="')+4;
        e = s + strfind(items{itemID}(s:end),'"')-2;
        t1 = items{itemID}(s:e);
        
        s = strfind(items{itemID},'<img')+4; s=s(1);
        e = s+strfind(items{itemID}(s:end),'/>')-2;
        img = items{itemID}(s:e);
        
        s = strfind(img,'http://'); s=s(1);
        e = s+strfind(img(s:end),'"')-2;        
        thumbnail = img(s:e);
        
        s = strfind(info,'imgurl:"')+8; s=s(1);
        e = s+strfind(info(s:end),'"')-2;        
        url = info(s:e);        
        
        cnt = cnt +1;
        
        result{cnt,1} = [info(1:end-1) ',"query":"' original_keywords '","title":"' t1 '","thumbnail":"' thumbnail '"}'];
        result{cnt,2} = url;
        result{cnt,3} = thumbnail;
    end
end

[~, uID ]=unique(result(:,2));

result = result(uID,:);
