clear
clc
close all

inFolder = 'B260595134347';
outName  = '../260595134347.mat';
label='B';
ID = '260595134347';


IRcamera = load(fullfile(inFolder,'left_depth/Calib_Results.mat'));
RGBcamera = load(fullfile(inFolder,'right_rgb/Calib_Results.mat'));
Stereocamera = load(fullfile(inFolder,'stereo_both/Calib_Results_stereo.mat'));

D.KK = IRcamera.KK;
D.fc = IRcamera.fc;
D.cc = IRcamera.cc;
D.kc = IRcamera.kc;
D.alpha_c = IRcamera.alpha_c;
D.width = IRcamera.nx;
D.height = IRcamera.ny;                  

RGB.KK = RGBcamera.KK;
RGB.fc = RGBcamera.fc;
RGB.cc = RGBcamera.cc;
RGB.kc = RGBcamera.kc;
RGB.alpha_c = RGBcamera.alpha_c;
RGB.width = RGBcamera.nx;
RGB.height = RGBcamera.ny;                  

D2RGB.R = Stereocamera.R;
D2RGB.T = Stereocamera.T/1000;
D2RGB.Rt = [D2RGB.R D2RGB.T];

[Y,X] = ndgrid(0:D.height-1,0:D.width-1);
x_kk = [X(:) Y(:)]';
x_n = normalize(x_kk,D.fc,D.cc,D.kc,D.alpha_c);

D.X = reshape(x_n(1,:),[D.height D.width]);
D.Y = reshape(x_n(2,:),[D.height D.width]);


[Y,X] = ndgrid(0:RGB.height-1,0:RGB.width-1);
x_kk = [X(:) Y(:)]';
x_n = normalize(x_kk,RGB.fc,RGB.cc,RGB.kc,RGB.alpha_c);
RGB.X = reshape(x_n(1,:),[RGB.height RGB.width]);
RGB.Y = reshape(x_n(2,:),[RGB.height RGB.width]);


f = (RGB.KK(1,1)+RGB.KK(2,2))/2;
RGB.K2render = [f 0 RGB.width/2; 0 f RGB.height/2; 0 0 1];

save(outName,'RGB','D','D2RGB','label','ID');

% http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
