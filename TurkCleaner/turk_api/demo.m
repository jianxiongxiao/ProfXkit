addpath /n/fs/vision/www/pvt/

FrameHeight = 630;
TemplateFileName = 'template.html';
TemplateString = file2string(TemplateFileName);
amazonHead = '<?xml version="1.0"?><HTMLQuestion xmlns="http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2011-11-11/HTMLQuestion.xsd"><HTMLContent><![CDATA[<!DOCTYPE html><html><head><title>HIT</title><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/><script type=''text/javascript'' src=''https://s3.amazonaws.com/mturk-public/externalHIT_v1.js''></script></head><body><form name="mturk_form" method="post" id="mturk_form" action="https://www.mturk.com/mturk/externalSubmit"><input type="hidden" value="" name="assignmentId" id="assignmentId" />';
amazonTail = ['</form><script language="Javascript">turkSetAssignmentID();</script></body></html>]]></HTMLContent><FrameHeight>' num2str(FrameHeight) '</FrameHeight></HTMLQuestion>'];
QuestionTemplate = [amazonHead TemplateString amazonTail];


% put your stuff here
for questionID=1:1000
    Question = QuestionTemplate;
    Question = strrep(Question,'${questionID}',num2str(questionID));
    Question = strrep(Question,'${data}','yinda fillin');
    Question = strrep(Question,'${examples}','yinda fillin');
    Question = strrep(Question,'${definition}','yinda fillin');
    Question = strrep(Question,'${question}','yinda fillin');
    Question = strrep(Question,'${listname}','yinda fillin');
end

