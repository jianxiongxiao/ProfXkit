function barColor(values, range, delta, edgecolor)

% generate a nice color bar based on the values
% values: data to plot by bar(values)
% range:  the min and max range for the x ticks
% delta:  the interval for the x ticks
% 
% example: barColor(1:30, [-1 1], 0.2)

if ~exist('range','var')
    range = [1 length(values)];
end
if ~exist('delta','var')
    delta = 1;
end
if ~exist('edgecolor','var')
    %edgecolor = 'none';
    edgecolor = [0 0 0];
end

colors = getNcolors(length(values));

for i=1:numel(values)
    patch([i-1 i-1 i i],...
        [0 values(i) values(i) 0],...
        colors(i,:),...
        'edgecolor',...
        edgecolor);
end
xlim([0 numel(values)])
grid on
nstep = (max(range) - min(range))/delta;
xtick = 0:(numel(values)/nstep):(numel(values));
set(gca,'XTick',xtick)

clear labels;
for i=1:nstep+1
    labels{i} = num2str(min(range)+(i-1)*delta);
end
set(gca,'XTickLabel',labels);