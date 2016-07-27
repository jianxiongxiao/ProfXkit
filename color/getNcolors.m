function colors = getNcolors(n)

% return N nice colors

colors = hsv(n);
offset = ceil(size(colors,1)*0.9);
colors = colors([offset:end 1:offset-1],:);
colors = colors(end:-1:1,:);