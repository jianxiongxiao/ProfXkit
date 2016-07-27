
function depth = get_depth(depth)
    depth = bitor(bitshift(depth,-3), bitshift(depth,16-3));
    depth = double(depth)/1000;
end