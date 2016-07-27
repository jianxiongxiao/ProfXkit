load cameraRTxj.mat

addpath /n/fs/vision/www/pvt/
addpath /n/fs/vision/www/pvt/drawCamera/

scale = 0.0001;

drawCameraPly('~/Downloads/cam1.ply',extrinsicsC2WframeTestDevice{1},scale);
drawCameraPly('~/Downloads/cam2.ply',extrinsicsC2WframeTestDevice{2},scale);
drawCameraPly('~/Downloads/cam3.ply',extrinsicsC2WframeTestDevice{3},scale);
drawCameraPly('~/Downloads/cam4.ply',extrinsicsC2WframeTestDevice{4},scale);

