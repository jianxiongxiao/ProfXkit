function image = readImage(pano,camera,image_width,image_height,image_seg,camera_info,folder)



segment = image_seg(1,image_seg(2,:) <= pano & image_seg(3,:) >= pano);
image_raw = imread(fullfile(folder, sprintf('segment_%.2d/unstitched_%.6d_%.2d.jpg',segment, pano,camera)));


[X,Y]= meshgrid(1:image_width,1:image_height);
delta_x = X(:) - (image_width /2+0.5);
delta_y = Y(:) - (image_height/2+0.5);


[x_raw,y_raw,inValid]=DistortedPosition(delta_x,delta_y,camera_info(camera+1));


image = warpImageFast(im2double(image_raw),reshape(x_raw,image_height,image_width), reshape(y_raw,image_height,image_width));

if ~isempty(inValid)
    image(inValid)=0;
    image(inValid+image_width*image_height)=0;
    image(inValid+image_width*image_height*2)=0;
end