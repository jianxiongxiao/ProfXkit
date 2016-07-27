function M = mergeCSV(M1, M2)

T1 = M1(1,:);
T2 = M2(1,:);

mapping = [];
cnt = length(T1);
for c=1:length(T2)
    ind = find(ismember(T1,T2{c}));
    if isempty(ind)
        cnt = cnt + 1;
        ind = cnt;
    end
    mapping(end+1) = ind;
end

M = M1;

M(size(M1,1)+1:size(M1,1)+size(M2,1)-1,mapping) = M2(2:end,:);
M(1,mapping) = M2(1,:);
