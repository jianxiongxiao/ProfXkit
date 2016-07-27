function vec = cameraRt2AngleAxis(Rt)

vec = RotationMatrixToAngleAxis(Rt(1:3,1:3));
vec = [vec Rt(1:3,4)'];
