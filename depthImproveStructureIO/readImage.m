function image = readImage(data,frameID)

image = imread(data.image{frameID});

%image = image(:,end:-1:1,:);

%image = read(data.image,frameID);
