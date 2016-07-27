clear;
clc;

sequenceName = '2014-04-11_17-09-54_094959634447';
data = loadSUN3Dv2(sequenceName);


frameIDs = 1:100:301;
frames = getRGBDframe(data,frameIDs);

Rts(:,:,1) = [eye(3) zeros(3,1)];

for i = 2:length(frameIDs)
    Rts(:,:,i) = align2RGBD(frames(:,:,:,i-1), frames(:,:,:,i));
    Rts(:,:,i) = concatenateRts(Rts(:,:,i-1), Rts(:,:,i));
end

ptsAll = [];
rgbAll = [];

for i = 1:length(frameIDs)
    [pts, rgb] = getPointsFromRGBD(frames(:,:,:,i));
    pts = transformPointCloud(pts,Rts(:,:,i));    
    
    ptsAll = [ptsAll pts];
    rgbAll = [rgbAll rgb];
end

points2ply('demo_sfm.ply', ptsAll, rgbAll);
