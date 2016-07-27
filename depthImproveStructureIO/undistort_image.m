function [imc] = undistort_image(im, KK, kc, nx, ny, KK_new)

fc = [ KK(1, 1); KK(2, 2) ];
alpha_c = 0;
cc = [ KK(1,3); KK(2, 3) ];

dist_amount = 1; %(1+kc(1)*r2_extreme + kc(2)*r2_extreme^2);
fc_new = dist_amount * fc;

if ~exist('KK_new','var')
    KK_new = [fc_new(1) alpha_c*fc_new(1) cc(1);0 fc_new(2) cc(2) ; 0 0 1];
end


I = im;

if (size(I,1)>ny)|(size(I,2)>nx),
    I = I(1:ny,1:nx);
end;

%% SHOW THE ORIGINAL IMAGE:
%{
if size(I,3) == 3
    figure(2);
    image(uint8(I));
    title('Original image (with distortion) - Stored in array I')
    axis equal;
    axis tight;    
    drawnow;
else
    figure(2);
    image(I);
    colormap(gray(256));
    axis equal;
    axis tight;    
    title('Original image (with distortion) - Stored in array I');
    drawnow;
end
%}

%% UNDISTORT THE IMAGE:

fprintf(1,'Computing the undistorted image...')

if size(I,3) == 3
    [Ipart_1] = rect(I(:,:,1),eye(3),fc,cc,kc,alpha_c,KK_new);
    [Ipart_2] = rect(I(:,:,2),eye(3),fc,cc,kc,alpha_c,KK_new);
    [Ipart_3] = rect(I(:,:,3),eye(3),fc,cc,kc,alpha_c,KK_new);

    I2 = ones(ny, nx,3);
    I2(:,:,1) = Ipart_1;
    I2(:,:,2) = Ipart_2;
    I2(:,:,3) = Ipart_3;

    fprintf(1,'done\n')
    
    %{
    figure(3);
    image(uint8(I2));
    axis equal;
    axis tight;
    %}
else
    [I2] = rect(I,eye(3),fc,cc,kc,alpha_c,KK_new);
    
    fprintf(1,'done\n');
    
    %{
    figure(3);
    image(I2);
    colormap(gray(256));
    axis equal;
    axis tight;
    %}
end;

%title('Undistorted image - Stored in array I2')
%drawnow;

    
imc = I2;

%