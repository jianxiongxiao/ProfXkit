getdepthRefined_structureIO
it take the one directory "directory" and do
1. depth refinement
function to refine depth:
[depthRefined, image] = SiftFuv2warpFast(directory,frameIDtarget, interval);

2. calculate extrinsic
3. put it to annotation folder under /n/fs/sun3d/data/SUNRGBDv2/
4. give you a link "webpagelink" for annotation.

For example :
https://sun3d.cs.princeton.edu/player/?name=SUNRGBDv2/2015-11-08T15.25.26.534-0000005351/&box3D=true&write=true&annotation=annotation3Dfinal&width=640&height=480&R=true&&highlight=false&rect=only

Remember run it on server so the permission can be changed correctly,
I haven't test it on server because of the intrinsic file.

