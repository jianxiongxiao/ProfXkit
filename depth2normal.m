function normalMap = depth2normal(XYZcam,f)

points3D = reshape(XYZcam,[],4)';

hasDepth = XYZcam(:,:,4)>0;

width  = size(XYZcam,2);
height = size(XYZcam,1);

[viewMap(:,:,1) viewMap(:,:,2)] = meshgrid(1:width,1:height);
viewMap(:,:,1) = viewMap(:,:,1) - width/2 - 0.5;
viewMap(:,:,2) = viewMap(:,:,2) - height/2 - 0.5;
viewMap(:,:,3) = f;
viewMap = viewMap/f;
viewVectors = reshape(viewMap,[],3)';
viewVectors = viewVectors(:,hasDepth(:));
%points2ply('~/Downloads/views3D.ply', points3D(1:3,hasDepth(:)), [], viewVectors*0.1);


normals = points2normals(points3D(1:3,hasDepth(:)));

dotp = sum(normals .* viewVectors,1)>0;
normals(:,dotp) = - normals(:,dotp);
normalMap = zeros([size(hasDepth) 3]);
normalMap(repmat(hasDepth(:),3,1))= [normals(1,:) normals(2,:) normals(3,:)];

%figure
%imagesc((normalMap+1)/2); axis equal; axis tight; axis off; colorbar;
%points2ply('~/Downloads/normals3D.ply', points3D(1:3,hasDepth(:)), [], normals*0.3);
