function [x_raw,y_raw,inValid]=DistortedPosition(delta_x,delta_y,camera_info)




if strcmp(camera_info.distortion_type, 'PERSPECTIVE')
%{
PERSPECTIVE Camera Projection Formula
Everything is in camera coordinate system
Input: x_dir, y_dir
Output: x_raw, y_raw
Distortion Coeffs: k1, k2, k3, p1, p2, fov_max
Intrinsics: fx, fy, cx, cy

r_max = tan( fov_max / 360.0 * PI)
r2_max = r_max ^ 2

x2 = x_dir ^ 2
y2 = y_dir ^ 2
r2 = x2 + y2

if ( r2 > r2_max ) WILL NOT PROJECT

xy = x_dir * y_dir

dist_scale = 1 + k1 * r2 + k2 * r2 ^ 2 + k3 * r2 ^ 3;
x_distorted = dist_scale * x_dir + 2 * p1 * xy + p2 * (r2 + 2 * x2)
y_distorted = dist_scale * y_dir + p1 * ( r2 + 2 * y2 ) + 2 * p2 * xy

x_raw = fx * x_distorted + cx
y_raw = fy * y_distorted + cy    
    
% code from Fisher:
double delta_x = undistorted_image_position.X() - center_x;
double delta_y = undistorted_image_position.Y() - center_y;
RNAngle x_dir = atan( delta_x / focal_x );
RNAngle y_dir = atan( delta_y / focal_y );
double x2 = x_dir * x_dir;
double y2 = y_dir * y_dir;
double r2 = x2 + y2;
double r_max = tan( fov_max / 360.0 * RN_PI);
double r2_max = r_max * r_max;
if ( r2 > r2_max ) return R2Point(-1,-1);
double xy = x_dir * y_dir;
double dist_scale = 1 + k1*r2 + k2*r2*r2 + k3*r2*r2*r2;
double x_distorted = dist_scale * x_dir + 2 * p1 * xy + p2 * (r2 + 2 * x2);
double y_distorted = dist_scale * y_dir + p1 * ( r2 + 2 * y2 ) + 2 * p2 * xy;
double x_pixel = focal_x * x_distorted + center_x;
double y_pixel = focal_y * y_distorted + center_y;
return R2Point(x_pixel, y_pixel);
%}

    image_raw_width = 1936;
    image_raw_height= 2592;    
    
    cx = (image_raw_width /2+0.5);
    cy = (image_raw_height/2+0.5);
    
    x_dir = atan( delta_x / camera_info.focal_x );
    y_dir = atan( delta_y / camera_info.focal_y );    
    
    r_max = tan( camera_info.fov_max / 360.0 * pi);
    r2_max = r_max ^ 2;

    x2 = x_dir .^ 2;
    y2 = y_dir .^ 2;
    r2 = x2 + y2;

    inValid = find( r2 > r2_max );

    xy = x_dir .* y_dir;

    dist_scale = 1 + camera_info.k1 .* r2 + camera_info.k2 .* (r2 .^ 2) + camera_info.k3 .* (r2 .^ 3);
    x_distorted = dist_scale .* x_dir + 2 * camera_info.p1 * xy + camera_info.p2 * (r2 + 2 * x2);
    y_distorted = dist_scale .* y_dir + camera_info.p1 * ( r2 + 2 * y2 ) + 2 * camera_info.p2 * xy;

    x_raw = camera_info.focal_x * x_distorted + cx;
    y_raw = camera_info.focal_y * y_distorted + cy;
    
    % let invalid ones be NaN
    x_raw(inValid) = NaN;
    y_raw(inValid) = NaN;
        
else
%{
FISHEYE Camera Projection Formula
Everything is in camera coordinate system
Input: x_dir, y_dir
Output: x_raw, y_raw
Distortion Coeffs: k1, k2, fov_max
Intrinsics: fx, fy, cx, cy

r_max = tan( fov_max / 360.0 * PI)
r2_max = r_max ^ 2

r2 = x_dir ^ 2 + y_dir ^ 2;

r = sqrt ( r2 )

if (r > 1e-8) {
  theta = atan( r )
  theta_tilde = theta * ( 1 + k1 * theta ^ 2 + k2 *theta ^ 4 ) / r
}
else
  theta_tilde = 1

x_distorted = theta_tilde * x_dir
y_distorted = theta_tilde * y_dir

x_raw = fx * x_distorted + cx
y_raw = fy * y_distorted + cy
%}
    
end