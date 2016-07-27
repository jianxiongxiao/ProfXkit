load demo.mat

%{
xx = fill_depth_cross_bfx(image, x, mask);
yy = fill_depth_cross_bfx(image, y, mask);
zz = fill_depth_cross_bfx(image, z, mask);

x = xx; y = yy; z = zz;
M = 15;
gv = fspecial('sobel');
gh = gv';
hx = imfilter(x, ones(M,M), 'replicate');
hy = imfilter(y, ones(M,M), 'replicate');
hz = imfilter(z, ones(M,M), 'replicate');
hx = imfilter(hx, gh, 'replicate');
hy = imfilter(hy, gh, 'replicate');
hz = imfilter(hz, gh, 'replicate');
hh = [hx(:), hy(:), hz(:)];

vx = imfilter(x, ones(M,M), 'replicate');
vy = imfilter(y, ones(M,M), 'replicate');
vz = imfilter(z, ones(M,M), 'replicate');
vx = imfilter(vx, gv, 'replicate');
vy = imfilter(vy, gv, 'replicate');
vz = imfilter(vz, gv, 'replicate');
vv = [vx(:), vy(:), vz(:)];

rr = cross(hh, vv);
h = size(xx, 1);
w = size(xx, 2);
a = reshape(rr(:,1), h, w);
b = reshape(rr(:,2), h, w);
c = reshape(rr(:,3), h, w);
s = sqrt(a.*a + b.*b + c.*c + 1e-6);
a = a./s;
b = b./s;
c = c./s;

a = (a + 1)/2;
b = (b + 1)/2;
c = (c + 1)/2;

%figure(1); imagesc(a);
%figure(2); imagesc(b);
%figure(3); imagesc(c);
nm = cat(3, a, b, c);
imwrite(nm, 'normal.ppm');

%}