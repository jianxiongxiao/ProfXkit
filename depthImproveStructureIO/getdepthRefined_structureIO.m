function getdepthRefined_structureIO(id)
%cd /n/fs/sun3d/code/SiftFuv2StructureIO
%/n/fs/vision/ionicNew/starter.sh getdepthRefined_structureIO 20000mb 120:00:00 1 300 1 /n/fs/modelnet/log/

basicSetup;
interval =20;
OuputPath = '/n/fs/sun3d/data/SUNRGBDv2/';
webtemplate = 'https://sun3d.cs.princeton.edu/player/?name=SUNRGBDv2/%s/&box3D=true&write=true&annotation=annotation3Dfinal&width=640&height=480&R=true&&highlight=false&rect=only';
%directory ='/net/pvd00/p/sunrgbd/mingrub/data_capture/11082015/single_image/2015-11-08T15.25.26.491/';
directory ='/Users/shurans/Downloads/2015-11-08T15.25.26.491/';
load(fullfile(directory,'metadata.mat'))
frameIDtarget = metadata.main_Id;
filename = metadata.main_frame(1:end-4);
folder = [fullfile(OuputPath,filename) '/'];
%% get web page link
webpagelink = sprintf(webtemplate,filename);
display(webpagelink)

if ~metadata.bad
    %% refine the depth
    [depthRefined, image] = SiftFuv2warpFast(directory,frameIDtarget, interval);

    %% put it into folder 
    mkdir([folder 'annotation/']);
    mkdir([folder 'annotation3D/']);
    system(sprintf('chmod -R 777 %sannotation/',folder));
    system(sprintf('chmod -R 777 %sannotation3D/',folder));
    mkdir([folder 'depth/']);
    mkdir([folder 'extrinsics/']);
    mkdir([folder 'image/']); 
    depth = uint16(depthRefined*1000);
    depth = bitor(bitshift(depth,3), bitshift(depth,-13));
    imwrite(depth,sprintf('%s/depth/%s.png',folder,filename));
    imwrite(image,sprintf('%s/image/%s.jpg',folder,filename));
    
    data = loadStructureIOdata(directory,[]);
    fid = fopen([folder 'intrinsics.txt'],'w');
    K = data.K';
    fprintf(fid,'%f %f %f\n%f %f %f\n%f %f %f\n',K(1),K(2),K(3),K(4),K(5),K(6),K(7),K(8),K(9));
    fclose(fid);
    %% get extrinsics
   
    depth = depthRefined;
    [x,y] = meshgrid(1:size(depth,2), 1:size(depth,1));
    XYZcamera(:,:,1) = (x-data.K(1,3)).*depth/data.K(1,1);
    XYZcamera(:,:,2) = (y-data.K(2,3)).*depth/data.K(2,2);
    XYZcamera(:,:,3) = depth;
    XYZcamera(repmat(depth==0,[1,1,3])) = NaN;
    X = XYZcamera(:,:,1);Y = XYZcamera(:,:,3);Z = -XYZcamera(:,:,2);

    [Rtilt,R] = rectify(cat(3,X,Y,Z));
    cameraRt =[eye(3) zeros(3,1)];
    cameraRt(1:3,1:3) =[1 0 0; 0 0 -1 ;0 1 0]*Rtilt*[1 0 0; 0 0 -1 ;0 1 0]';
    timeStamp = clock;
    timeStamp = sprintf('%.4d%.2d%.2d%.2d%.2d%.2d',timeStamp(1),timeStamp(2),timeStamp(3),timeStamp(4),timeStamp(5),round(timeStamp(6)));    
    delete([folder '/extrinsics/*.txt'])
    fp = fopen([folder '/extrinsics/' timeStamp '.txt'],'w');
    for rowID=1:size(cameraRt,1)
        fprintf(fp, '%f %f %f %f\n',cameraRt(rowID,:));
    end
    
    system(sprintf('chmod -R 775 %s',folder));
    
    
end
        
%%
%{
if 0 
    rgb = [reshape(image(:,:,1),[],1),reshape(image(:,:,2),[],1),reshape(image(:,:,3),[],1)];
    figure,
    XYZnew = Rtilt*[X(:),Y(:),Z(:)]';
    vis_point_cloud(XYZnew',double(rgb),40,4000);
end
points2ply('refined.ply', [X(:),Y(:),Z(:)], rgb)
%}
end