function mesh2offbinary(OFFfilename, faces,vertices)
% output a mesh into an OFF file
% input:
% OFFfilename is the file name for the off file
% vertices is Nx3 matrix for vertex index
% faces is KxD matrix. D is the number of polygon size. =3 if triangles


file = fopen(OFFfilename,'w');
fprintf (file, 'OFF BINARY\n');
fwrite(file, int32(size(vertices,1)), 'int32');
fwrite(file, int32(size(faces,1)), 'int32');
fwrite(file, int32(0), 'int32');
for v=1:size(vertices,1)
    fwrite(file, single(vertices(v,1)), 'single');
    fwrite(file, single(vertices(v,2)), 'single');
    fwrite(file, single(vertices(v,3)), 'single');
end

faces = faces -1; % matlab starts from 1, office starts from 0

for f=1:size(faces,1)
    fwrite(file, int32(size(faces,2)), 'int32');
    for i=1:size(faces,2)
        fwrite(file, int32(faces(f,i)), 'int32');
    end
end

fclose(file);
