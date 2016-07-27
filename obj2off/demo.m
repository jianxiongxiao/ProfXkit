
if ~exist('objFname','var')
    objFname = 'example/model.obj';
end

if ~exist('plyFname','var')
    plyFname = 'example/model.ply';
end


OBJ=read_wobj(objFname);

faces = [];
for i=1:length(OBJ.objects)
    if strcmp(OBJ.objects(i).type,'f')
        faces = [faces; OBJ.objects(i).data.vertices];
    end
end

% check duplicates
for i=1:size(faces,1)
    faces(i,:) = sort(faces(i,:));
end
faces = unique(faces,'rows');

vertices = OBJ.vertices;

% orientation
vertices = PCAvertex(vertices')';

% normalize height
[vertices, xrange, zrange] = normalizeHeight(vertices);

% saving
%mesh2off(offFname, faces,vertices);
%mesh2offbinary(offFname, faces,vertices);
patch2ply(plyFname, vertices', faces');