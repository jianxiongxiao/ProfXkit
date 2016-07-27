function DirT = transformRTdir(Dir,Rt)

DirT = Rt(1:3,1:3) * Dir;

