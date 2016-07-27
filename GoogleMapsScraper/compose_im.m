function im_mosaic = compose_im(url, center_x, center_y, xhalf, yhalf, zoom)

im_mosaic = uint8(zeros((yhalf*2+1)*256,(xhalf*2+1)*256,3));
for x=(center_x-xhalf):(center_x+xhalf)
    for y=(center_y-yhalf):(center_y+yhalf)
        im_mosaic(((y-(center_y-yhalf))*256+1):((y-(center_y-yhalf)+1)*256),((x-(center_x-xhalf))*256+1):((x-(center_x-xhalf)+1)*256),:) = ...
            imread(sprintf(url,x,y,zoom));
    end
end