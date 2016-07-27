
interval = 150;


sequenceName{1} = 'Shuran/bedroom_funiturestore/2014-05-26_14-41-22_260595134347';
frameID(1) = 34;

for i=1:length(sequenceName)
    [depthRefined, image] = SiftFuv2warpFast(sequenceName{i},frameID(i),interval);
    
    depth = uint16(depthRefined*1000);
    depth = bitor(bitshift(depth,3), bitshift(depth,-13));

    %{
    depthDecode = bitor(bitshift(depth,-3), bitshift(depth,16-3));
    depthDecode = double(depthDecode)/1000;
    imagesc(depthRefined - depthDecode)
    max(max(abs(depthRefined - depthDecode)))
    %}
    
    
    imwrite(depth,'/Users/xj/Desktop/depthmap.png');
    
    % subsample depth
    depthSubsampled = depth(1:2:end,1:2:end);
    imwrite(depthSubsampled,'/Users/xj/Desktop/depthmapSubsample.png');
    
    imageSubsampled = image(1:2:end,1:2:end,:);
    imwrite(imageSubsampled,'/Users/xj/Desktop/imageSubsampled.jpg');
end
