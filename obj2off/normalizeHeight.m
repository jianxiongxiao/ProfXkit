function [vertices, xrange, zrange] = normalizeHeight(vertices)

% vertices is Nx3 matrix

minx = min(vertices(:,1));  maxx = max(vertices(:,1));
miny = min(vertices(:,2));  maxy = max(vertices(:,2));
minz = min(vertices(:,3));  maxz = max(vertices(:,3));

cx = (maxx+minx)/2;
cy = (maxy+miny)/2;
cz = (maxz+minz)/2;

vertices(:,1) = vertices(:,1)-cx;
vertices(:,2) = vertices(:,2)-cy;
vertices(:,3) = vertices(:,3)-cz;

vertices = vertices/(maxy-miny);

xrange = maxx-minx;
zrange = maxz-minz;
