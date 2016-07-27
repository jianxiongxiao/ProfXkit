
function XYZtransform = transformPointCloud(XYZ,Rt)
    XYZtransform = Rt(1:3,1:3) * XYZ + repmat(Rt(1:3,4),1,size(XYZ,2));
end

