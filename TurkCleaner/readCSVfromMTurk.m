function MM = readCSVfromMTurk(filename)

% read CSV for turk. the matlab function doesn't work
% written by jianxiong xiao. can handle "" in json encoding for Mturk

fid=fopen(filename,'r');
slurp=fscanf(fid,'%c');
fclose(fid);
M=strread(slurp,'%s','delimiter','\n');

for i=1:length(M)
    k=1;
    cnt = 0;
    while k < length(M{i})
        if M{i}(k)== '"'
            for j=k+1:length(M{i})
                if M{i}(j)=='"'
                    if j==length(M{i}) || ( M{i}(j+1)~='"' && (M{i}(j-1)~='"' || j==k+1))
                        cnt = cnt + 1;
                        MM{i,cnt} = regexprep(M{i}(k+1:j-1),'""','"');
                        k = j;
                        break;
                    end
                end
            end
        end
        k = k+1;
    end
end


%{

    
    pos=findstr(M{i},'"');

    doubleQuote = [pos(1:end-1)+1 == pos(2:end), false ];
    doubleQuote = doubleQuote | [false doubleQuote(1:end-1)];
    
    commaPos=findstr(M{i},',');
    
    pos = pos(~doubleQuote);
    for j=1:2:length(pos)
        MM{i,(j+1)/2}= regexprep(M{i}(pos(j)+1:pos(j+1)-1),'""','"');
    end
    
    j=1;
    cnt = 0;
    while j<length(pos)
        if pos(j)+1 ~= pos(j+1)
            cnt = cnt + 1;
            MM{i,cnt} = 
            j = j+2;
        end
    end
    
    
    for j=1:2:length(pos)
%}