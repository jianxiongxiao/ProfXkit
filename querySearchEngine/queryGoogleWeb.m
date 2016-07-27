function result = queryGoogleWeb(original_keywords,data_from, data_to)

% example usage:  result = queryGoogleWeb();

if ~exist('original_keywords','var')
    original_keywords = 'wedding room';
    data_from = '1/1/2000';
    data_to   = '2/1/2010';
end

keywords = regexprep(original_keywords,' ','+');

url_template = 'http://www.google.com/search?q=%s&hl=en&biw=2510&bih=1488&ijn=%d&tbm=isch&start=%d';

% example
%url_template = [url_template '&tbs=cdr:1,cd_min:1/1/2013,cd_max:2/1/2013'];
if exist('data_from','var')
    url_template = [url_template '&tbs=cdr:1,cd_min:' data_from ',cd_max:' data_to];
end

% add this to add the time
% &tbs=cdr:1,cd_min:4/28/2014,cd_max:4/2/2014 is the time: http://stenevang.wordpress.com/2013/02/22/google-search-url-request-parameters/


% tbm=isch means to search image. See http://stenevang.wordpress.com/2013/02/22/google-search-url-request-parameters/
% ijn=2 or &ijn=sbg
% sa=X <== safe search
% hl=en <== english?
% https://www.google.com/search?q=wedding&sa=X&tbs=cdr:1,cd_min:4/28/2014,cd_max:4/2/2014&biw=1826&bih=714&tbm=isch&ijn=2&ei=bOFjU87KM8ilyASd0IGICg&start=200


result = [];

for first = 0:100:900
    url = sprintf(url_template,keywords,first/100,first);
    
    % directly call Matlab function
    % html = urlread(url);
    html = wgetRead(url);

    resultNow = parseGoogle(html,keywords);
    fprintf('%d: length = %d entries = %d\n',first,length(html), size(resultNow,1));
    %first = first+size(resultNow,1);    
    result = [result; resultNow];
end

%{
first = 979;
url = sprintf(url_template,keywords,first);
%html = urlread(url);
html = wgetRead(url);

resultNow = parseGoogle(html,keywords);
fprintf('%d: length = %d entries = %d\n',first,length(html), size(resultNow,1));
result = [result; resultNow];
%}

%result = parseGoogle(myStr,keywords);

[~, uID ]=unique(result(:,2));

result = result(uID,:);

end

function str = wgetRead(url)
%    wgetTemplate = '/usr/local/bin/wget --tries=2 --timeout=5 "%s" --user-agent=\"Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6\" -O \"%s\"';
    wgetTemplate = '/usr/local/bin/wget --tries=2 --timeout=5 "%s" --referer="https://www.google.com/" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.131 Safari/537.36" -O "%s"';
    fname = tempname;
    system(sprintf(wgetTemplate,url,fname));
    try
        str = file2string(fname);
    catch
        str = '';
    end
    delete(fname);
end

function fileStr = file2string(fname)
    fileStr = '';
    fid = fopen(fname,'r');
    tline = fgetl(fid);
    while ischar(tline)
        fileStr = [fileStr sprintf('\n') tline];
        tline = fgetl(fid);
    end
    fclose(fid);
end

function result = parseGoogle(myStr,keywords)

% googleReg = '(title=")[^"]+(")';
googleReg = '(<a href="/imgres\?imgurl=)[^"]+(&amp;imgrefurl=)';
linkReg = '(&amp;imgrefurl=)[^"]+(&amp;h=)';
tbnidReg = '(images\?q=tbn)[^"]+(")';
metaReg = '(<div class="rg_meta">)[^<]+(</div>)';


urls = regexp(myStr,googleReg,'match');
refurls = regexp(myStr,linkReg,'match');
tbns = regexp(myStr,tbnidReg,'match');
metas = regexp(myStr,metaReg,'match');

result = cell(0,3);

cnt = 0;

for i=1:length(urls)
    % disp([num2str(i) ':  ' urls{i}(25:end-15)]);
    url = urls{i}(25:end-15);
    tbn = tbns{i}(14:end-1);
    refurl = refurls{i}(16:end-7);
    meta = metas{i}(23:end-7);
    
    meta = regexprep(meta,'\\u0026','&');
    meta = regexprep(meta,'\\u003d','=');
    meta = regexprep(meta,'\\u003c','<');
    meta = regexprep(meta,'\\u003e','>');
    meta = regexprep(meta,'&nbsp;',' ');
    meta = regexprep(meta,'&#215;','×');

    urlEscape = strrep(strrep(url,'\','\\'),'''','\''');

    
        %'"tbnid": "' strrep(strrep(strrep(tbn,'\','\\'),'"','\"'),'''','\''') '", ' ...
    info = [ '{'  ...
        '"keywrods": "' strrep(strrep(strrep(keywords,'\','\\'),'"','\"'),'''','\''') '", ' ...
        '"engine": "' 'google' '", ' ...
        '"url": "' urlEscape '", ' ...        
        '"refurl": "' strrep(strrep(strrep(refurl,'\','\\'),'"','\"'),'''','\''')  '", ' ...
        meta '}'];
    
    
    cnt = cnt + 1;
    result{cnt,1} = info;
    result{cnt,2} = urlEscape;
    result{cnt,3} = ['http://t0.gstatic.com/images?q=tbn:' tbn];    
end

end