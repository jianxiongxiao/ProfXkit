function [facesUnique,verticesUnique]=getUniqueVertex(faces,vertices)

% Some mesh has duplicate vertices that mess up many algorithms. 
% This function removes the redudancy of the mesh vertices.
%
% input:
% faces is Nx3 matrix for vertex index
% vertices is Kx3 matrix

[verticesUnique,~,ic] =unique(vertices,'rows');
facesUnique = ic(faces);
facesUnique = unique(facesUnique,'rows');

