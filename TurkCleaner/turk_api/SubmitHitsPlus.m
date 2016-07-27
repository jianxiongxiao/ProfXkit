function SubmitHitsPlus( input_path, startID, endID, sandbox )
%SUBMITHITS Summary of this function goes here
%   Detailed explanation goes here
load('./data/HITData.mat');
Title = hit.Title.Text;
Description = hit.Description.Text;
Description = [Description ' If some of the images are not loaded, please do NOT continue working and email us to fix them immediately.'];
Reward = hit.Reward;
AssignmentDurationInSeconds = hit.AssignmentDurationInSeconds.Text;
Keywords = hit.Keywords.Text;
QualificationRequirement = hit.QualificationRequirement;

LifetimeInSeconds = '604800';
MaxAssignments = '2';
AutoApprovalDelayInSeconds = '172800';

name = regexp(input_path,'/','split');
name2 =regexp(name{end},'\.','split');
RequesterAnnotation = ['Batch:' name2{1}];
if strcmp(input_path(1:6),'/n/fs/')
    parameter = gendataLsunNew(name2{1});
else
    parameter = gendataLsunNew(input_path);
end

fprintf('%d hits pending submission: $%3.2f\n', length(parameter), length(parameter)*2*0.2);
pause(60);

aws_access_key = 'AKIAIAGDVEVNP3ML45RQ';
aws_secret_key = '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';
% sandbox = false;
% sandbox = true;
turk = InitializeTurk(aws_access_key, aws_secret_key, sandbox);

%%
for bid = startID:min(endID,length(parameter))
    fprintf('%d/%d\n', bid, length(parameter));
    success = false; 
    Question2 = sprintf(QuestionPattern2, parameter(bid).DataStr(2:end-1), parameter(bid).exampleStr(2:end-1), ['''' parameter(bid).definitionStr '''']);
    Question = [QuestionPattern1 Question2 QuestionPattern3 parameter(bid).QuestionStr QuestionPattern4];
    
    while ~success
        try
            if ~sandbox
            status = RequestTurk(turk, 'CreateHIT', {'Title',Title,'Description',Description,...
                        'Reward.Amount',Reward.Amount.Text,...
                        'Reward.CurrencyCode',Reward.CurrencyCode.Text,...
                        'Reward.FormattedPrice',Reward.FormattedPrice.Text,...
                        'AssignmentDurationInSeconds',AssignmentDurationInSeconds,...
                        'LifetimeInSeconds',LifetimeInSeconds,'MaxAssignments',MaxAssignments,...
                        'Keywords',Keywords,'AutoApprovalDelayInSeconds',AutoApprovalDelayInSeconds,...
                        'RequesterAnnotation',RequesterAnnotation,...
                        'QualificationRequirement.1.QualificationTypeId',QualificationRequirement{1}.QualificationTypeId.Text, ...
                        'QualificationRequirement.1.Comparator',QualificationRequirement{1}.Comparator.Text, ...
                        'QualificationRequirement.1.IntegerValue',QualificationRequirement{1}.IntegerValue.Text, ...
                        'QualificationRequirement.1.RequiredToPreview',QualificationRequirement{1}.RequiredToPreview.Text, ...
                        'QualificationRequirement.2.QualificationTypeId',QualificationRequirement{2}.QualificationTypeId.Text, ...
                        'QualificationRequirement.2.Comparator',QualificationRequirement{2}.Comparator.Text, ...
                        'QualificationRequirement.2.IntegerValue',QualificationRequirement{2}.IntegerValue.Text, ...
                        'QualificationRequirement.2.RequiredToPreview',QualificationRequirement{2}.RequiredToPreview.Text, ...                       
                        'Question',Question});
            else
                status = RequestTurk(turk, 'CreateHIT', {'Title',Title,'Description',Description,...
                            'Reward.Amount',Reward.Amount.Text,...
                            'Reward.CurrencyCode',Reward.CurrencyCode.Text,...
                            'Reward.FormattedPrice',Reward.FormattedPrice.Text,...
                            'AssignmentDurationInSeconds',AssignmentDurationInSeconds,...
                            'LifetimeInSeconds',LifetimeInSeconds,'MaxAssignments',MaxAssignments,...
                            'Keywords',Keywords,'AutoApprovalDelayInSeconds',AutoApprovalDelayInSeconds,...
                            'RequesterAnnotation',RequesterAnnotation,...                     
                            'Question',Question});
            end
            
            if strcmp(status.CreateHITResponse.HIT.Request.IsValid.Text, 'True')
                success = true;
            else
                fprintf('%s\n', status.CreateHITResponse.HIT.Request.Errors.Error.Message.Text);
            end
        end
    end
end

%%
if ~sandbox
    if ~strcmp(input_path(end-3:end),'.txt')
        input_path = [input_path '.txt'];
    end
    new_batch_path = './data/New_Batches.txt';
    fp = fopen(new_batch_path,'a');
    fprintf(fp,'%s %s\n', RequesterAnnotation, input_path);
    fclose(fp);
end

end
