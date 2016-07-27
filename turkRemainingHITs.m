function turkRemainingHITs(input_csv_fname, result_csv_fname, output_csv_fname, uniqueColumn)
% this function take a turk input.csv file and result.csv file
% and output a file remaining_input.csv 
% for the HITs that haven't been done
% based on a specific column
%{
%example:
input_csv_fname    = '/data/vision/torralba/gigaSUN/inputTurk/c/cybercafe.csv';
result_csv_fname   = '/data/vision/torralba/gigaSUN/resultTurk/c/cybercafe.csv';
output_csv_fname   = '/data/vision/torralba/gigaSUN/inputTurk/c/cybercafe_2nd.csv';
uniqueColumn = 'sunID';
%}

input_csv  = readCSVfromMTurk(input_csv_fname);
result_csv = readCSVfromMTurk(result_csv_fname);

uniqueColumnIDinput = find(ismember(input_csv(1,:),uniqueColumn));    
uniqueColumnIDresult = find(ismember(result_csv(1,:),['Input.' uniqueColumn]));

good_input_row = [];
for row = 2:size(input_csv,1)
    if ~any(find(ismember(result_csv(2:end,uniqueColumnIDresult)',input_csv{row,uniqueColumnIDinput})))
        good_input_row(end+1) = row;
    end
end

fp = fopen(output_csv_fname,'w');
if ~isempty(good_input_row)
    
    fid = fopen(input_csv_fname,'r');
    tline = fgetl(fid);
    fprintf(fp,'%s\n',tline);
    for row = 2:size(input_csv,1)
        tline = fgetl(fid);
        if ~isempty(find(good_input_row, row))
            fprintf(fp,'%s\n',tline);
        end
    end
    fclose(fid);    
end
fclose(fp);
