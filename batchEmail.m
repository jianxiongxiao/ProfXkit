contactList{1,1} = 'title 1'; contactList{1,2} = 'author name 1'; contactList{1,3} = 'spam@email.com';
contactList{2,1} = 'title 2'; contactList{2,2} = 'author name 2'; contactList{2,3} = 'spam@email.com';



subjectLine = 'title of the emails';
bodyLine = ['Dear %s,\n',...
'\n',...
'We will be organizing XXX\n',...
'Sincerely,\n',...
'The Organizers'];
cmdLine = 'mail -s "%s" %s < email.txt';

for itemID =1:size(contactList,1)
    paperTitle = contactList{itemID,1};
    authorName = contactList{itemID,2};
    emailAddress = contactList{itemID,3};
    
    % write the file
    fp = fopen('email.txt','w');
    fprintf(fp,bodyLine,authorName, paperTitle);    
    fclose(fp);
    
    % run command
    cmd = sprintf(cmdLine,subjectLine,emailAddress);
    system(cmd);
    
    % delete file
    delete('email.txt');
end

