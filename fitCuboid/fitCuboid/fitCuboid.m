function location2D = fitCuboid(ptr, changeID)


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

Demo:
just run this function without any argument.

Function:

This program takes input of the image coordinate of the 7 corners of a
cuboid, and fit a 3D cuboid, and output the new image coordinate of the
corners.

If changeID is 1-7, it will ignore that corner, and use the rest of the
corners to estimate the result.
If changeID is 8, it will use all 7 corners to fit the cuboid.

Installation:

You need to have ceres (http://code.google.com/p/ceres-solver/) installed
in your machine (I only tested with version 1.3.0),
and compile the mex file by running compile.m

Cooridinate system:
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



%}

if ~exist('ptr','var')
    
    subplot(2,1,1);
    imshow(imread('SUNprimitive.jpg'));

    ptr=[
        80+10 52+10  % add some error +10 to test how it gets back
        53 3
        179 55
        62 145
        152 6
        162 146
        37 90];
    
    
    edge = [1 2; 1 3; 1 4; 2 5; 3 5; 3 6; 2 7; 4 7; 4 6];
    for e=1:size(edge,1)
        hold on
        plot(ptr(edge(e,:),2),ptr(edge(e,:),1),'-r','LineWidth',3);
    end
    title('input');
    
end
if ~exist('changeID','var')
    changeID = 1;
end

ptr = ptr';

%% initialization

X = [-1    -1     -1     1     -1      1      1;
    1     1     -1     1     -1     -1      1;
    1    -1      1     1     -1      1     -1];
x = ptr;
N = 7;

if changeID<8
    chooseVector = true(1,7);
    chooseVector(changeID) = false;
    X = X(:,chooseVector);
    x = x(:,chooseVector);
    N = 6;
end


xi = x(1,:);
yi = x(2,:);

% Estimate Q = P*L:
A = [[zeros(4,N); X; ones(1,N); -X(1,:).*yi; -X(2,:).*yi; -X(3,:).*yi]'; ...
    [-X; -ones(1,N); zeros(4,N); X(1,:).*xi; X(2,:).*xi; X(3,:).*xi]'];
b = [yi -xi]';
Q = [A\b; 1];
Q = reshape(Q,4,3)';

[K,R,t] = decomposeP(Q); % P = K*R*[eye(3) -t].

%xxx = K*R*[X-repmat(t,1,N)]; xxx(1:2,:)./xxx([3 3],:)

f=mean(K([1 5]));
px = K(7);
py = K(8);
%cuboidH = 1;
%cuboidW = 1;

%{
        px_init = scoreSize(2)/2;
        py_init = scoreSize(1)/2;
        cuboidH = px_init/px;
        cuboidW = py_init/py;
        f = mean([K(1,1)/cuboidH, K(2,2)/cuboidW]);
        cuboidH = K(1,1)/f;
        cuboidW = K(2,2)/f;
        px = K(1,3)/cuboidH;
        py = K(2,3)/cuboidW;
        t(1) = t(1) * cuboidH;
        t(2) = t(2) * cuboidW;
%}
% K = [f 0 px; 0 f py; 0 0 1];
% xxx = K*R*[diag([cuboidH,cuboidW,1])*X-repmat(t,1,N)]; xxx(1:2,:)./xxx([3 3],:)
% sum(sum((xxx(1:2,:)./xxx([3 3],:) - ptr(:,chooseVector)).^2))

parameter = [f,px,py,t',1,1,0,0,0];

%% least square fitting

[location2D,err] = fitCuboidMex(ptr,parameter,R, int32(changeID));

%% visualization for the demo
if exist('edge','var')
    subplot(2,1,2);
    imshow(imread('SUNprimitive.jpg'));    
    for e=1:size(edge,1)
        hold on
        plot(location2D(2,edge(e,:)),location2D(1,edge(e,:)),'-g','LineWidth',3);
    end    
    title('result');
end

%%
if changeID<8
    location2D = location2D(:,changeID)';
end


