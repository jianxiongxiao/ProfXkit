% code to download oblique images

clear
clc
close all

% location and zoom panorama
centerH.x = 634439;
centerH.y = 855591;
centerV.x = 775656;
centerV.y = 1341409;
zoom = 21;
xhalf = 20;
yhalf = 15;


center.x = centerH.x;
center.y = centerV.x;
totalxy = (2^zoom-1);
oblique0_im   = compose_im('https://khms1.google.com/kh?v=58&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=0',centerH.x,centerH.y, xhalf, yhalf,zoom);
oblique90_im  = compose_im('https://khms1.google.com/kh?v=58&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=90',centerV.x,centerV.y, xhalf, yhalf,zoom);
oblique180_im = compose_im('https://khms1.google.com/kh?v=58&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=180',totalxy-centerH.x,totalxy-centerH.y, xhalf, yhalf,zoom);
oblique270_im = compose_im('https://khms1.google.com/kh?v=58&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=270',totalxy-centerV.x,totalxy-centerV.y, xhalf, yhalf,zoom);


oblique0_depth   = compose_depth('https://khms0.google.com/kh?v=000015&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=0&db=dp&callback=_callbacks_',centerH.x,centerH.y, xhalf, yhalf,zoom);
oblique90_depth  = compose_depth('https://khms0.google.com/kh?v=000015&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=90&db=dp&callback=_callbacks_',centerV.x,centerV.y, xhalf, yhalf,zoom);
oblique180_depth = compose_depth('https://khms0.google.com/kh?v=000015&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=180&db=dp&callback=_callbacks_',totalxy-centerH.x,totalxy-centerH.y, xhalf, yhalf,zoom);
oblique270_depth = compose_depth('https://khms0.google.com/kh?v=000015&src=app&host=maps.google.com&x=%d&y=%d&z=%d&deg=270&db=dp&callback=_callbacks_',totalxy-centerV.x,totalxy-centerV.y, xhalf, yhalf,zoom);

aerial_im     = compose_im('https://khms1.google.com/kh/v=113&src=app&x=%d&y=%d&z=%d&s=Gal', center.x, center.y, xhalf, yhalf, zoom);

fname = sprintf('%d_%d_%d_%d_%d_%d_%d',centerH.x,centerH.y,centerV.x,centerV.y,zoom, xhalf, yhalf);
save([fname '.mat'], 'centerH','centerV', 'zoom','xhalf','yhalf','oblique0_im', 'oblique90_im', 'oblique180_im', 'oblique270_im', 'oblique0_depth', 'oblique90_depth', 'oblique180_depth', 'oblique270_depth', 'aerial_im');


imwrite(oblique0_im,[fname '_oblique0.png']);
imwrite(oblique90_im,[fname '_oblique90.png']);
imwrite(oblique180_im,[fname '_oblique180.png']);
imwrite(oblique270_im,[fname '_oblique270.png']);

imwrite(aerial_im,[fname '_aerial.png']);


figure
subplot(2,4,1); imshow(oblique0_im);  title(sprintf('%d x %d', size(oblique0_im,1), size(oblique0_im,2)));
subplot(2,4,2); imshow(oblique90_im); title(sprintf('%d x %d', size(oblique90_im,1), size(oblique90_im,2)));
subplot(2,4,3); imshow(oblique180_im);title(sprintf('%d x %d', size(oblique180_im,1), size(oblique180_im,2)));
subplot(2,4,4); imshow(oblique270_im);title(sprintf('%d x %d', size(oblique270_im,1), size(oblique270_im,2)));

subplot(2,4,5); imagesc(oblique0_depth); axis equal; axis tight; axis off;   title(sprintf('%d x %d', size(oblique0_depth,1), size(oblique0_depth,2)));
subplot(2,4,6); imagesc(oblique90_depth); axis equal; axis tight; axis off;  title(sprintf('%d x %d', size(oblique90_depth,1), size(oblique90_depth,2)));
subplot(2,4,7); imagesc(oblique180_depth); axis equal; axis tight; axis off; title(sprintf('%d x %d', size(oblique180_depth,1), size(oblique180_depth,2)));
subplot(2,4,8); imagesc(oblique270_depth); axis equal; axis tight; axis off; title(sprintf('%d x %d', size(oblique270_depth,1), size(oblique270_depth,2)));



figure; imshow(aerial_im);