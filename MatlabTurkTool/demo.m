
% get access key from
% from: https://aws-portal.amazon.com/gp/aws/developer/account/index.html?ie=UTF8&action=access-key

aws_access_key = ;
aws_secret_key = ;
sandbox = true;

turk = InitializeTurk(aws_access_key, aws_secret_key, sandbox);


% operation list from:
% http://docs.amazonwebservices.com/AWSMechTurk/latest/AWSMturkAPI/ApiReference_OperationsArticle.html

result = RequestTurk(turk, 'GetAccountBalance', {'ResponseGroup.0','Minimal','ResponseGroup.1','Request'});

result.GetAccountBalanceResponse.GetAccountBalanceResult.AvailableBalance.Amount.Text
