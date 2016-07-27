function depth =denoise(depth,camera_D)



XYZcamera(:,:,1)=camera_D.X .* depth;
XYZcamera(:,:,2)=camera_D.Y .* depth;
XYZcamera(:,:,3)=depth .* (~isnan(camera_D.X) & ~isnan(camera_D.Y));

%figure;imagesc(XYZcamera(:,:,3)); axis equal; axis tight;

X = reshape(XYZcamera,[],3);

validID = find(X(:,3)~=0);

X = X(validID,:);



%points2ply('original.ply', X);


% denoise

kdOBJ = KDTreeSearcher(X);


[~,mindist] = knnsearch(kdOBJ,X,'K',4);

threshold1 = 0.1;
threshold2 = 0.2;
threshold3 = 0.25;
threaholdFurthest = 8; %15;
threaholdClosest = 0.5;

goodones = mindist(:,2)<threshold1 & mindist(:,3)<threshold2 & mindist(:,4)<threshold3 & X(:,3)<threaholdFurthest & X(:,3)>threaholdClosest ;

XYZcamera( 2*camera_D.width*camera_D.height + validID(~goodones)) = 0;
X = X(goodones,:);

%figure;imagesc(XYZcamera(:,:,3)); axis equal; axis tight;


%points2ply('filter1.ply', X);


depth3Max = ordfilt2(XYZcamera(:,:,3),23,true(5));

outliers = XYZcamera(:,:,3) > (depth3Max + 0.5) & (depth3Max>0);
XYZcamera( 2*camera_D.width*camera_D.height + find(outliers)) = 0;

%figure;imagesc(XYZcamera(:,:,3)); axis equal; axis tight;

%depthMed = medfilt2(XYZcamera(:,:,3), [5 5]);
%XYZcamera(:,:,3)

%X = reshape(XYZcamera,[],3);
%validID = find(X(:,3)~=0);
%X = X(validID,:);
%points2ply('filter2.ply', X);

depth = XYZcamera(:,:,3);