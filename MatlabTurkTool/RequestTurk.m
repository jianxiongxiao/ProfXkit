function result = RequestTurk(turk, operation, params)



timestamp = UTCtimestamp();
signature = HMACencode(['AWSMechanicalTurkRequester', operation, timestamp], turk.aws_secret_key);

paramsFixed = ...
{'AWSAccessKeyId',turk.aws_access_key, ...
 'Version','2012-03-25', ...
 'Signature',signature, ...
 'Timestamp',timestamp,...
 'Operation',operation};

params = [paramsFixed params];

result_string = urlread(turk.service_url,'post',params);

result = parseXMLstring(result_string);

%{
Example:

https://mechanicalturk.amazonaws.com/?Service=AWSMechanicalTurkRequester
&AWSAccessKeyId=[the Requester's Access Key ID]
&Version=2012-03-25
&Operation=GetAccountBalance
&Signature=[signature for this request]
&Timestamp=[your system's local time]
&ResponseGroup.0=Minimal
&ResponseGroup.1=Request
%}
