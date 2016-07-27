filename = 'Batch_56319_batch_results.csv';

M = readCSVfromMTurk(filename);

Input_question_col = find(ismember(M(1,:),'Input.question'));
Input_data_col = find(ismember(M(1,:),'Input.data'));
Answer_answer_col  = find(ismember(M(1,:),'Answer.answer'));

for row = 2:size(M,1)
    disp(row);
    question = M{row,Input_question_col};
    data = loadjson(M{row,Input_data_col});
    answer = M{row,Answer_answer_col};
    for i=1:length(data)
        data{i}.answer = answer(i)=='1';
    end
    
    for i=1:length(data)
        if data{i}.answer
            figure
            imshow(imread(data{i}.image));
            title(question);
        end
    end
    
end
