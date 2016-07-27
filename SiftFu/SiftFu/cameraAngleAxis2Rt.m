function Rt = cameraAngleAxis2Rt(vec)

Rt = AngleAxisToRotationMatrix(vec(1:3));
Rt(1:3,4) = vec(4:6);
