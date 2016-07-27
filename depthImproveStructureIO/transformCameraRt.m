function RtOut = transformCameraRt(RtIn)

RtOut = [RtIn(1:3,1:3)', - RtIn(1:3,1:3)'* RtIn(1:3,4)];
