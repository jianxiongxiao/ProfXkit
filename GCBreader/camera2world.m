function Xworld = camera2world(Xcam,translation,rotation)

dcm = RotationMatrix(quaternion(rotation));

Xworld =  dcm * Xcam + repmat(translation,1,size(Xcam,2));
