function visualizePolarHist(rhos)
% plot a polar histogram as shown in the 4-th row of Figure 6 in the paper
% Please cite this paper if you use this code:
% J. Xiao, K. A. Ehinger, A. Oliva and A. Torralba
% Recognizing Scene Viewpoint using Panoramic Place Representation
% Proceedings of 25th IEEE Conference on Computer Vision and Pattern Recognition (CVPR2012)

if nargin<1
    % example
    rhos = [ 0.7338 0.7066 0.7168 1.6148 0.6969 0.7072 0.7178 0.000 0.7405 0.7683 0.7683 0.7683];
end

nOrientation = numel(rhos);
theatas =  -pi:(2*pi/nOrientation):pi-(2*pi/nOrientation);
theatas = -theatas;
rhos = rhos([(end/4+1):end 1:end/4]);

theatas = ...
    [   theatas+ pi/nOrientation; ...
    theatas+ pi/nOrientation; ...
    theatas- pi/nOrientation; ...
    theatas- pi/nOrientation ];
rhos = ...
    [   zeros(1,length(rhos)); ...
    rhos;    ...
    rhos;    ...
    zeros(1,length(rhos)) ];

nStep = 20;

theatas([nStep+2 nStep+3],:) = theatas([3 4],:);
rhos([nStep+2 nStep+3],:) = rhos([3 4],:);
rhos(3:(nStep+1),:) = repmat(rhos(2,:),nStep-1,1);


for i=1:nStep
    theatas(i+2,:) = theatas(2,:) * (nStep-i) / nStep + theatas(nStep+2,:) * i / nStep;
end

theatas = theatas(:)';
rhos = rhos(:)';

clf
polarMy4(theatas,rhos,'-');




