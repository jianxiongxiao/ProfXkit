% Library:
% We use the Off-screen Rendering library from Mesa3D:
% http://www.mesa3d.org/osmesa.html
% You will need to have libosmesa6-dev or newer version of osmesa installed.
% in linux command line: sudo apt-get install libosmesa6-dev

% install lOSMesa
% compile
% mex RenderMex.cpp -lGLU -lOSMesa
% or
% mex RenderMex.cpp -lGLU -lOSMesa -I/media/Data/usr/Mesa-9.1.2/include


depth = off2im('chair000009.off');

imagesc(depth)
axis equal
axis tight
colorbar
% unit is meter
