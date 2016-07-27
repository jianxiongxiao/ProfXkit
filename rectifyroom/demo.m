load('data');
[Rtilt,R] = rectify(cat(3,X,Y,Z));

figure,
XYZnew = Rtilt*[X(:),Y(:),Z(:)]';
scatter3(XYZnew(1,1:10:end),XYZnew(2,1:10:end),XYZnew(3,1:10:end),1,rgb(1:10:end,:));
axis equal;


figure,
XYZnew = R*[X(:),Y(:),Z(:)]';
scatter3(XYZnew(1,1:10:end),XYZnew(2,1:10:end),XYZnew(3,1:10:end),1,rgb(1:10:end,:));
axis equal;