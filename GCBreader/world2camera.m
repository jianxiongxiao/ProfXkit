function Xcam = world2camera(Xworld,translation,rotation)

dcm = RotationMatrix(quaternion(rotation));

if size(Xworld,1)~=3
    Xworld = Xworld';
end

Xcam = dcm \ (Xworld - repmat(translation,1,size(Xworld,2)));
