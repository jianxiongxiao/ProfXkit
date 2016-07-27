function [image,depth, info]=point2render(coordinate, rgb, image, depth, info)
% render a point cloud to an image
% note that we assume the coordinate is the camera coordinates
% for example, if you have a camera matrix P
% you should input P*X as your coordinate
% coordinate and rgb are 3*n matrix
% rgb is double color from [0,1]

%{
% if you have many point cloud to accumulate. You can use it like this:
for frameID=1:N
    if frameID == 1
        [image,depth, info]=point2render(XYZworld, RGB);
    else
        [image,depth]=point2render(XYZworld, RGB, image, depth, info);
    end
end
%}

if ~exist('info','var')
    info.range.minX = -10;
    info.range.maxX =  10;
    info.range.minY = -10;
    info.range.maxY =  10;
    info.unit = 0.01;
end

if ~exist('image','var') || ~exist('depth','var')
    sizeX = ceil((info.range.maxX - info.range.minX)/info.unit);
    sizeY = ceil((info.range.maxY - info.range.minY)/info.unit);
    image = ones(sizeX,sizeY,3);
    depth = -Inf(sizeX,sizeY);
end
sizeXY = numel(depth);

coordinateX = (coordinate(1,:) - info.range.minX)/info.unit;
coordinateY = (coordinate(2,:) - info.range.minY)/info.unit;


coordinateXi = round(coordinateX);
coordinateYi = round(coordinateY);

valid = find((1<= coordinateXi) & (coordinateXi <= size(depth,1)) & (1<= coordinateYi) & (coordinateYi <= size(depth,2)));

index = sub2ind(size(depth),coordinateXi(valid),coordinateYi(valid));

toColor = depth(index) < coordinate(3,valid);

valid = valid(toColor);
index = index(toColor);

[~, swapOrder]= sort(coordinate(3,valid));
valid = valid(swapOrder);
index = index(swapOrder);


image(index)          = rgb(1,valid);
image(index+sizeXY)   = rgb(2,valid);
image(index+sizeXY*2) = rgb(3,valid);
depth(index)          = coordinate(3,valid);

