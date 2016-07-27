% In-paints the depth image using a cross-bilateral filter. The operation 
% is implemented via several filterings at various scales. The number of
% scales is determined by the number of spacial and range sigmas provided.
% 3 spacial/range sigmas translated into filtering at 3 scales.
%
% Args:
%   imgRgb - the RGB image, a uint8 HxWx3 matrix
%   imgDepthAbs - the absolute depth map, a HxW double matrix whose values
%                 indicate depth in meters.
%   spaceSigmas - (optional) sigmas for the spacial gaussian term.
%   rangeSigmas - (optional) sigmas for the intensity gaussian term.
%
% Returns:
%    imgDepthAbs - the inpainted depth image.
function imgDepthAbs = fill_depth_cross_bfx(imgRgb, imgDepthAbs, mask, ...
    spaceSigmas, rangeSigmas)
  
  error(nargchk(2,4,nargin));
  assert(isa(imgRgb, 'uint8'), 'imgRgb must be uint8');
  assert(isa(imgDepthAbs, 'double'), 'imgDepthAbs must be a double');

  if nargin < 4 
    spaceSigmas = [12 5 8];
  end
  if nargin < 5
    rangeSigmas = [0.2 0.08 0.02];
  end
  
  assert(numel(spaceSigmas) == numel(rangeSigmas));
  assert(isa(rangeSigmas, 'double'));
  assert(isa(spaceSigmas, 'double'));
  
  % Create the 'noise' image and get the maximum observed depth.
  maxv = max(imgDepthAbs(~mask));
  minv = min(imgDepthAbs(~mask));
  
  % Convert the depth image to uint8.
  imgDepth = (imgDepthAbs - minv) ./ (maxv - minv);
  imgDepth = uint8(imgDepth * 255);
  
  % Run the cross-bilateral filter.
  imgDepthAbs = mex_cbf(imgDepth, rgb2gray(imgRgb), mask, spaceSigmas(:), rangeSigmas(:));
  
  % Convert back to absolute depth (meters).
  imgDepthAbs = im2double(imgDepthAbs) .* (maxv - minv) + minv;
end
