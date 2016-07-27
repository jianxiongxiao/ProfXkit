load('point2mesh_data.mat')

frameIdtarget=50; %<= the actual frame ID. e.g. frameIds=200:301; frameIdtarget=150;

[points, faces] = TSDFmesh(data, frameIdtarget, frameIds,cameraRtC2W);

patch2ply('mesh.ply', points);