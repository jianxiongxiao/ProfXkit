% this function will read a google download html file and covert it
% into mysql batch command file

%{
<a href="/imgres?imgurl=http://schools.archchicago.org/images/highschools/18.jpg&amp;imgrefurl=http://schools.archchicago.org/schools/schoollistcity.aspx&amp;h=266&amp;w=324&amp;sz=18&amp;tbnid=o2GpciHX-BLS1M:&amp;tbnh=97&amp;tbnw=118&amp;prev=/search%3Fq%3DSt%2BLawrence%2BHigh%2BSchool%26tbm%3Disch%26tbo%3Du&amp;zoom=1&amp;q=St+Lawrence+High+School&amp;hl=en&amp;usg=__rJUTw9RaoQnXQDkaKqPEJ7j_K9g=&amp;sa=X&amp;ei=Bl-DTuTXGOa80AGCuKCqAQ&amp;ved=0CAMQ9QEwAA"><img src="data:image/gif;base64,R0lGODlhAQABAIAAAP///////yH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" alt="" align=middle border=1 height=97 id=imgthumb1 class="imgthumb1" title="http://schools.archchicago.org/schools/schoollistcity.aspx" style="display:-moz-inline-box;height:97px;margin:3px 3px 3px 3px;padding:0px 0px;width:118px" width=118></a>
%}

function outObj = readGoogleObj(googleFname, outObj, topic_mid, keywords)


inFP = fopen(googleFname, 'r');

myStr = '';

tline = fgetl(inFP);
while ischar(tline)
    myStr = [myStr tline];
    tline = fgetl(inFP);
end

% googleReg = '(title=")[^"]+(")';
googleReg = '(<a href="/imgres\?imgurl=)[^"]+(&amp;imgrefurl=)';
linkReg = '(&amp;imgrefurl=)[^"]+(&amp;h=)';
tbnidReg = '(&amp;tbnid=)[^"]+(&amp;tbnh=)';


urls = regexp(myStr,googleReg,'match');
refurls = regexp(myStr,linkReg,'match');
tbns = regexp(myStr,tbnidReg,'match');

for i=1:length(urls)
    % disp([num2str(i) ':  ' urls{i}(25:end-15)]);
    url = urls{i}(25:end-15);
    tbn = tbns{i}(12:end-10);
    refurl = refurls{i}(16:end-7);
    urlEscape = strrep(strrep(url,'\','\\'),'''','\''');

    
    info = ['{"tbnid": "' strrep(strrep(strrep(tbn,'\','\\'),'"','\"'),'''','\''')  ...
        '", "keywrods": "' strrep(strrep(strrep(keywords,'\','\\'),'"','\"'),'''','\''') ...
        '", "mid": "' strrep(strrep(strrep(topic_mid,'\','\\'),'"','\"'),'''','\''') ...
        '", "engine": "' 'google' ...
        '", "url": "' urlEscape ...        
        '", "refurl": "' strrep(strrep(strrep(refurl,'\','\\'),'"','\"'),'''','\''') '"}'];
    
    
    cnt = size(outObj,1);
    cnt = cnt + 1;
    outObj{cnt,1} = urlEscape;
    outObj{cnt,2} = info;
    outObj{cnt,3} = 'google';
    
end

fclose(inFP);

% image google cache: http://t0.gstatic.com/images?q=tbn:CxufgEqJNk3pXM: