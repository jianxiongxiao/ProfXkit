function [coordinate, rgb] = getPointsFromRGBD(RGBDframe)

X = reshape(RGBDframe(:,:,[1 2 3 5 6 4]),[],6)';
valid = X(6,:) > 0;

coordinate = X(4:6,valid);
rgb = X(1:3,valid);
