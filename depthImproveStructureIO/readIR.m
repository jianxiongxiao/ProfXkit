function IR = readIR(data,frameID)

IR = imread(data.ir{frameID});

IR = IR(:,end:-1:1,:);
