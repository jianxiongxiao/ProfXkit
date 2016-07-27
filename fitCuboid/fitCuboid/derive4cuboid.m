% some randome equations used for deriving the math. You don't need to look at this unless you know what you are doing.
%{
Author:
Jianxiong Xiao: http://mit.edu/jxiao/

Citation:
Please cite the following paper if you use this code in all possible ways.

@inproceedings{CuboidDetector,
 author = "Jianxiong Xiao and Bryan C. Russell and Antonio Torralba",
 title = "Localizing 3D Cuboids in Single-view Images",
 booktitle = "Advances in Neural Information Processing Systems (NIPS)",
 year = "2012",
 month = "December",
 address = "Lake Tahoe, USA"
}
%}

clear
syms CAM_F CAM_PX CAM_PY CAM_RX CAM_RY CAM_RZ CAM_TX CAM_TY CAM_TZ CAM_H CAM_W 

% CAM_F=parameter(1); CAM_PX=parameter(2); CAM_PY=parameter(3); CAM_RX=parameter(4); CAM_RY=parameter(5); CAM_RZ=parameter(6); CAM_TX=parameter(7); CAM_TY=parameter(8); CAM_TZ=parameter(9); CAM_H=parameter(10); CAM_W=parameter(11);

%syms rx2 ry2 rz2 rw2 rw

rx2 = CAM_RX^2;
ry2 = CAM_RY^2;
rz2 = CAM_RZ^2;
rw2 = 1 - rx2 - ry2 - rz2;
rw = sqrt(rw2);

rxy = CAM_RX*CAM_RY; rxz = CAM_RX*CAM_RZ; ryz = CAM_RY*CAM_RZ;
rwx = rw*CAM_RX; rwy = rw*CAM_RY; rwz = rw*CAM_RZ;
    
R = [rw2+rx2-ry2-rz2 , 2*(rxy - rwz) , 2*(rwy + rxz)
     2*(rwz + rxy) , rw2-rx2+ry2-rz2 , 2*(ryz - rwx)
     2*(rxz - rwy) , 2*(rwx + ryz) , rw2-rx2-ry2+rz2];

%{
    y
    ^
    |
    |    2-------------7
    |    |\             \
    |    | 1-------------4
    |    | |             |
    |    5 |             |
    |     \|             |
    |      3-------------6
    |
    |
    +----------------------------->x
   /
  /
 /
L
z
     
X = [-1    -1     -1     1     -1      1      1;
      1     1     -1     1     -1     -1      1;
      1    -1      1     1     -1      1     -1];

%}     
% P = K*R*[eye(3) -t]. 
     
    
     
X = [-CAM_H     -CAM_H    -CAM_H    CAM_H    -CAM_H     CAM_H    CAM_H;
      CAM_W      CAM_W    -CAM_W    CAM_W    -CAM_W    -CAM_W    CAM_W;
         1          -1         1        1        -1         1       -1];
Y = X - repmat([CAM_TX;CAM_TY;CAM_TZ],1,7);     

ccode(Y,'file','Y.cpp');


syms RYx1 RYy1 RYz1
syms RYx2 RYy2 RYz2


K = [ CAM_F 0 CAM_PX;
      0 CAM_F CAM_PY;
      0 0  1];
Z = K* [RYx1 RYx2; RYy1 RYy2; RYz1 RYz2];
zz = Z(1:2,:)./Z([3 3],:);

ccode(zz,'file','Z.cpp')