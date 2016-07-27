addpath tensorIO_matlab

clear

clf

tensors = readTensors('outTSDF.tensor');

    
tsdf = tensors(1).value;


%% visualization
%{

for i=1:size(tsdf,3)
    imagesc((tsdf(end:-1:1,end:-1:1,i))',[0 1]); axis equal; axis tight; colorbar
    title(i);
    pause(0.1);
end

%return;

for i=1:size(tsdf,2)
    imagesc((reshape(tsdf(:,i,:), [size(tsdf,1) size(tsdf,3)])),[0 1]); axis equal; axis tight; colorbar
    pause(0.1);
    title(i);
end


for i=1:size(tsdf,1)
    imagesc((reshape(tsdf(i,end:-1:1,:), [size(tsdf,2) size(tsdf,3)])),[0 1]); axis equal; axis tight; colorbar
    title(i);
    pause(0.1);
end
%}


%% meshing
disp('isosurfacing...');
tic;
fv = isosurface(tsdf,0);
toc;
% visualizaiton
%{
figure(3);
p = patch(fv);
p.FaceColor = 'red';
p.EdgeColor = 'none';
daspect([1,1,1])
view(3); axis tight
camlight 
lighting gouraud
%}

unit = 0.0005;

fv.vertices = fv.vertices * unit;

fv.vertices(:,1) = fv.vertices(:,1) - mean(fv.vertices(:,1));
fv.vertices(:,2) = fv.vertices(:,2) - mean(fv.vertices(:,2));
fv.vertices(:,3) = fv.vertices(:,3) - mean(fv.vertices(:,3));

mesh2off('isosurface.off', fv.faces,fv.vertices);
