function image = autoCropImage(image)
% input an image
% output an image with white space removed
% assuming the top left pixel is the background color that you don't want

mask = mean(image,3);
mask = mask == mask(1,1);
isGood1 = find(any(~mask,1));
isGood2 = find(any(~mask,2));
image = image(min(isGood2):max(isGood2),min(isGood1):max(isGood1), :);