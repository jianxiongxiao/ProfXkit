clear
load data.mat
close all;
count = zeros(1,8);

dispC = 15;
dispR = 15;

for i=1:length(data)
    clear map
    [img,map] = imread(['http://gigasun.csail.mit.edu/image/' data{i}]);
    
    if ndims(img)>3
        result = 'animation';
    else
        if ~isempty( map )
            img = ind2rgb( img, map );
            img = im2uint8(img);
        end
        
        [result,imgNew] = isGoodPhoto(img);
        
        while strcmp(result,'crop')
            %figure
            %imshow(img)
            img = imgNew;
            [result,imgNew] = isGoodPhoto(img);
        end
    end
    
    switch(result)
        case 'good'
            figure(1); set(1,'Name','good','NumberTitle','off')
            count(1) = count(1) + 1;
            subplot(dispR,dispC,count(1));
            imshow(img); title(i);
        case 'too small'
            %figure(2); set(2,'Name','too small','NumberTitle','off')
            count(2) = count(2) + 1;
            %subplot(dispR,dispC,count(2));
            %imshow(img); title(i);
        case 'flickr empty'
            figure(3); set(3,'Name','flickr empty','NumberTitle','off')
            count(3) = count(3) + 1;
            subplot(dispR,dispC,count(3));
            imshow(img); title(i);        
        case {'too white','too black','too pure','binary'}
            figure(4); set(4,'Name','too white too black too pure binary','NumberTitle','off')
            count(4) = count(4) + 1;
            subplot(dispR,dispC,count(4));
            imshow(img); title(i);

        case 'crop'
            count(7) = count(7) + 1;
            figure(7); set(7,'Name','crop','NumberTitle','off')
            subplot(dispR,dispC,count(7));
            imshow(img); title(i);            

            count(7) = count(7) + 1;
            figure(7); set(7,'Name','crop','NumberTitle','off')
            subplot(dispR,dispC,count(7));
            imshow(imgNew); title(i);                    

            figure(1);
            count(1) = count(1) + 1;
            subplot(dispR,dispC,count(1));
            imshow(imgNew); title(i);            
            
        case 'animation'
            count(8) = count(8) + 1;
    end
end



