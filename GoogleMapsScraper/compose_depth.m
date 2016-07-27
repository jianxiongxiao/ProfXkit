function depth_mosaic = compose_depth(url, center_x, center_y, xhalf, yhalf, zoom)


depthSquare = 65;



depth_mosaic = zeros((yhalf*2+1)*depthSquare,(xhalf*2+1)*depthSquare);
for x=(center_x-xhalf):(center_x+xhalf)
    for y=(center_y-yhalf):(center_y+yhalf)
        % 
        str = urlread(sprintf(url,x,y,zoom));
        
        pos = findstr(str,'depth_data": "');
        depth_str = str(pos+14:end);
        pos = findstr(depth_str,'"');
        depth_str = depth_str(1:pos-1);
        
        
        fid = fopen('tmp.txt', 'w');
        fprintf(fid, depth_str);
        fclose(fid);
        system('python decodeJPEG.py tmp.txt');
        im = imread('tmp.jpg');
        delete('tmp.txt');
        delete('tmp.jpg');
        
        
        pos = findstr(str,'"near": ');
        near = str(pos+8:end);
        pos = findstr(near,',');
        near = near(1:pos-1);
        near = str2num(near);
        
        pos = findstr(str,'"far": ');
        far = str(pos+7:end);
        pos = findstr(far,',');
        far = far(1:pos-1);
        far = str2num(far); 
        
        
        im = im2double(im)*(near - far) + far;
        
        
        depth_mosaic(((y-(center_y-yhalf))*depthSquare+1):((y-(center_y-yhalf)+1)*depthSquare),((x-(center_x-xhalf))*depthSquare+1):((x-(center_x-xhalf)+1)*depthSquare)) = im;
        
    end
end