function texturedVRML2(outputFname,vertex, face, textureUV, textureImageFile)
%{
  outputFname is the file name for VRML2 file. usualy it is *.wrl
      when it is done, open the file in meshlab
  vertex is 3xN points
  face is KxM faces (index for faces with K vertices and M face in total. 
        K=3 for triangulated mesh. K=4 for rectangular mesh.)
  textureUV is KxMx2 uv coordinates for each vertice of the faces
        (all values should be from 0 to 1)
  texture coordinate system

  V (0,1)      (1,1)
  ^
  |
  |
  |
  +--------> U (1,0)
 (0,0)

  more document: http://www.c3.hu/cryptogram/vrmltut/part6.html
%}

fp = fopen(outputFname,'w');
fprintf(fp,'#VRML V2.0 utf8\n');
fprintf(fp,'Shape{ geometry IndexedFaceSet{\n');
fprintf(fp,'coord Coordinate{point[\n');
for i=1:size(vertex,2)
    fprintf(fp,'%f %f %f,\n',vertex(1,i),vertex(2,i),vertex(3,i));
end
fprintf(fp,']}\n');
fprintf(fp,'coordIndex[\n');
for i=1:size(face,2)
    for j=1:size(face,1)
        fprintf(fp,'%d,',face(j,i));
    end
    fprintf(fp,'-1,\n');
end
fprintf(fp,']\n');
fprintf(fp,'texCoord TextureCoordinate{point[\n');
for i=1:size(textureUV,2)
    for j=1:size(textureUV,1)
        fprintf(fp,'%f %f\n',textureUV(j,i,1),textureUV(j,i,2));
    end
end
fprintf(fp,']}\n');
fprintf(fp,'texCoordIndex[\n');
cnt =0;
for i=1:size(textureUV,2)
    for j=1:size(textureUV,1)
        fprintf(fp,'%d ',cnt);
        cnt=cnt+1;
    end
    fprintf(fp,'-1\n');
end
fprintf(fp,']\n');
fprintf(fp,'}\n');
fprintf(fp,'appearance Appearance{material Material{diffuseColor 1 1 1 }  texture ImageTexture { url "%s" } }\n',textureImageFile);
fprintf(fp,'}\n');
fclose(fp);
end
