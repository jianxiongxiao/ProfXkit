% This is a Matlab reader to demonstrate how to load Google CityBlock R5 data
% The data is copyrighted by Google, and we are not allowed to distribute
% the data. But if you can get the data from Google directly, you can use
% this code to load the data.
% Written by Jianxiong Xiao @ 2013

%% path to load the data
rootPath = '/n/fs/gsv/data/%s/original/raw_data';
run = 'paris_1';
city = strsplit(run,'_'); city = city{1};
rootPath = sprintf(rootPath,city);

%% load and parse the data

camera_info = readCameraInfo(fullfile(rootPath, run,'camera_info.txt'));
metadata = readMetaData(fullfile(rootPath, run,'metadata.txt'));
[image_seg,image_seg_header] = readTable(fullfile(rootPath, run,'image_seg.txt'));
obj_1 = readObj(fullfile(rootPath, run,'laser_point_cloud_1.obj'));
obj_2 = readObj(fullfile(rootPath, run,'laser_point_cloud_2.obj'));
obj_3 = readObj(fullfile(rootPath, run,'laser_point_cloud_3.obj'));
[image_pose,image_pose_header] = readTable(fullfile(rootPath, run,'image_pose.txt'));
[laser_pose_1,laser_pose_1_header] = readTable(fullfile(rootPath, run,'laser_pose_1.txt'));
[laser_pose_2,laser_pose_2_header] = readTable(fullfile(rootPath, run,'laser_pose_2.txt'));
[laser_pose_3,laser_pose_3_header] = readTable(fullfile(rootPath, run,'laser_pose_3.txt'));
index_image_position_x =find(ismember(image_pose_header,'position_x'));
index_image_position_y =find(ismember(image_pose_header,'position_y'));
index_image_position_z =find(ismember(image_pose_header,'position_z'));
index_image_quaternion_x =find(ismember(image_pose_header,'quaternion_x'));
index_image_quaternion_y =find(ismember(image_pose_header,'quaternion_y'));
index_image_quaternion_z =find(ismember(image_pose_header,'quaternion_z'));
index_image_quaternion_w =find(ismember(image_pose_header,'quaternion_w'));

% save(run);

%% all the following code is for visualizaiton to demonstrate how to use the data

%% plot the world 
figure
for i=1:1000
    plot3(obj_1(i).v(1,:),obj_1(i).v(2,:),obj_1(i).v(3,:),'.b'); hold on
    plot3(obj_2(i).v(1,:),obj_2(i).v(2,:),obj_2(i).v(3,:),'.k'); hold on
    plot3(obj_3(i).v(1,:),obj_3(i).v(2,:),obj_3(i).v(3,:),'.r'); hold on
end
axis equal;
xlabel('x');
ylabel('y');
zlabel('z');

%% plot the camera to demonstrate how to convert a point from camera to world coordinate system
approximateScanlineID = 968;
cameraAxisScale = 0.1;
for pano=000000:00050
    for camera=0:length(camera_info)-1
        index = find(image_pose(1,:)==pano & image_pose(2,:)==camera);
        % use the middle scanline to approximate the pose for rolling shutter
        index = index(approximateScanlineID);
        
        translation = image_pose([index_image_position_x index_image_position_y index_image_position_z],index);
        rotation    = image_pose([index_image_quaternion_w index_image_quaternion_x index_image_quaternion_y index_image_quaternion_z],index);

        Xcam = [eye(3) zeros(3,1)] * cameraAxisScale;

        Xworld = camera2world(Xcam,translation,rotation);
        plot3(Xworld(1,[1 4]),Xworld(2,[1 4]),Xworld(3,[1 4]),'-r'); hold on
        plot3(Xworld(1,[2 4]),Xworld(2,[2 4]),Xworld(3,[2 4]),'-g'); hold on
        plot3(Xworld(1,[3 4]),Xworld(2,[3 4]),Xworld(3,[3 4]),'-b'); hold on
    end
end
xlabel('x');
ylabel('y');
zlabel('z');

%% how to load an image and correct the radio distortion
pano = 0;
camera = 0;
image = readImage(pano,camera,1936,2592,image_seg,camera_info,fullfile(rootPath, run));

%% overlay the laser on the image to demonstrate how to project a 3D point from World to image
index = find(image_pose(1,:)==pano & image_pose(2,:)==camera);
translation = image_pose([index_image_position_x index_image_position_y index_image_position_z],index);
rotation    = image_pose([index_image_quaternion_w index_image_quaternion_x index_image_quaternion_y index_image_quaternion_z],index);

figure
imshow(image); hold on;
for i=1:1000
    for j=1:size(obj_1(i).v,2)
        Xworld = [obj_1(i).v(1,j);obj_1(i).v(2,j);obj_1(i).v(3,j)];
        [x,y, column_index]=UndistortedPosition(Xworld,camera_info(camera+1),translation, rotation);
        x = x+size(image,2)/2;
        y = y+size(image,1)/2; 
        if ~isnan(x) && 1< column_index && column_index < 1936
            plot(x,y,'.b'); hold on
        end
    end
end
for i=1:1000
    for j=1:size(obj_3(i).v,2)
        Xworld = [obj_3(i).v(1,j);obj_3(i).v(2,j);obj_3(i).v(3,j)];
        [x,y, column_index]=UndistortedPosition(Xworld,camera_info(camera+1),translation, rotation);
        x = x+size(image,2)/2;
        y = y+size(image,1)/2; 
        if ~isnan(x) && 1< column_index && column_index < 1936
            plot(x,y,'.r'); hold on
        end
    end
end

%% plot on the camera coordinate system to demonstrate how to convert from world coordinate to camera coordinate
Xworld1 = [];
Xworld3 = [];
for i=1:1000
    Xworld1 = [Xworld1 obj_1(i).v];
    Xworld3 = [Xworld3 obj_3(i).v];
end
Xcamera1 = world2camera(Xworld1,translation(:,1936/2),rotation(:,1936/2));
Xcamera3 = world2camera(Xworld3,translation(:,1936/2),rotation(:,1936/2));
figure
plot3(Xcamera1(1,:),Xcamera1(2,:),Xcamera1(3,:),'.b'); hold on;
plot3(Xcamera3(1,:),Xcamera3(2,:),Xcamera3(3,:),'.r'); hold on;
axis equal;
xlabel('x');
ylabel('y');
zlabel('z');

