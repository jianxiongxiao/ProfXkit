load demo.mat    
pitch =  -120/180*pi;
yaw = -30/180*pi;
pitchR = [1           0           0           ;...
          0           cos(pitch)  -sin(pitch) ;...
          0           sin(pitch)  cos(pitch)  ];
yawR =   [cos(yaw)    0           sin(yaw)  ;...
          0           1           0           ;...
          -sin(yaw)   0           cos(yaw)  ];

R = pitchR * yawR ;

Rt = [R [0.8;0;12]];

width = 640*1;
height= 480*1;
K = [  1100*1    0  width/2 ;...
         0  1100*1  height/2 ;...
         0    0    1];
[render,depth] = RenderPCcameraMatlab(double(pt),color, ptCamera,colorCamera ,K, Rt,width,height);
imshow(render);
imwrite(render,'demo.png');
