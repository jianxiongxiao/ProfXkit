function [x,y,last_column_index]=UndistortedPosition(world_position,camera_info,translation, rotation)

width = size(translation,2);

% Search for x coordinate (there is a different camera pose for every column)
column_index = width / 2;
last_column_index = column_index;

for i=1:width/2
    
    camera_position = world2camera(world_position,translation(:,column_index),rotation(:,column_index));
        
    if camera_position(3)<=0
        x = NaN;
        y = NaN;
        return;
    end

    % Compute coordinates of projection
    x = camera_position(1) / camera_position(3) * camera_info.focal_x;
    y = camera_position(2) / camera_position(3) * camera_info.focal_y;
    
    %return; % debug
        
    % Get/check column index
    [distorted_position_x, ~] = DistortedPosition(x,y,camera_info);
    if isnan(distorted_position_x)
        x = NaN;
        y = NaN;
        return;
    end
    
    column_index = round(distorted_position_x + 0.5);
    
    if (column_index < 1)
        column_index = 1;
    end
    if (column_index > width)
        column_index = width;
    end
    if (column_index == last_column_index)
        break;
    end
    last_column_index = column_index;
end

