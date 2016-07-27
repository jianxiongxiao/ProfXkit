function turk = InitializeTurk(aws_access_key, aws_secret_key, sandbox)

if ~exist('sandbox','var')
    sandbox = true;
end

turk.aws_access_key = aws_access_key;
turk.aws_secret_key = aws_secret_key;

if sandbox
    turk.service_url='https://mechanicalturk.sandbox.amazonaws.com/?Service=AWSMechanicalTurkRequester';
else
    turk.service_url='https://mechanicalturk.amazonaws.com/?Service=AWSMechanicalTurkRequester';
end
    
% Operation List 
disp('Operation List:');
disp('http://docs.amazonwebservices.com/AWSMechTurk/latest/AWSMturkAPI/ApiReference_OperationsArticle.html');

