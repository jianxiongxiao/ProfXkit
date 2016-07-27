function hpol = polarMy4(varargin)
    %POLAR  Polar coordinate plot.
    %   POLAR(THETA, RHO) makes a plot using polar coordinates of
    %   the angle THETA, in radians, versus the radius RHO.
    %   POLAR(THETA, RHO, S) uses the linestyle specified in string S.
    %   See PLOT for a description of legal linestyles.
    %
    %   POLAR(AX, ...) plots into AX instead of GCA.
    %
    %   H = POLAR(...) returns a handle to the plotted object in H.
    %
    %   Example:
    %      t = 0 : .01 : 2 * pi;
    %      polar(t, sin(2 * t) .* cos(2 * t), '--r');
    %
    %   See also PLOT, LOGLOG, SEMILOGX, SEMILOGY.
    
    %   Copyright 1984-2010 The MathWorks, Inc.
    %   $Revision: 5.22.4.10 $  $Date: 2010/05/20 02:25:28 $
    
    % Parse possible Axes input
    [cax, args, nargs] = axescheck(varargin{:});
    error(nargchk(1, 3, nargs, 'struct'));
    
    if nargs < 1 || nargs > 3
        error('MATLAB:polar:InvalidInput', 'Requires 2 or 3 data arguments.');
    elseif nargs == 2
        theta = args{1};
        rho = args{2};
        if ischar(rho)
            line_style = rho;
            rho = theta;
            [mr, nr] = size(rho);
            if mr == 1
                theta = 1 : nr;
            else
                th = (1 : mr)';
                theta = th(:, ones(1, nr));
            end
        else
            line_style = 'auto';
        end
    elseif nargs == 1
        theta = args{1};
        line_style = 'auto';
        rho = theta;
        [mr, nr] = size(rho);
        if mr == 1
            theta = 1 : nr;
        else
            th = (1 : mr)';
            theta = th(:, ones(1, nr));
        end
    else % nargs == 3
        [theta, rho, line_style] = deal(args{1 : 3});
    end
    if ischar(theta) || ischar(rho)
        error('MATLAB:polar:InvalidInputType', 'Input arguments must be numeric.');
    end
    if ~isequal(size(theta), size(rho))
        error('MATLAB:polar:InvalidInput', 'THETA and RHO must be the same size.');
    end
    
    % get hold state
    cax = newplot(cax);
    
    next = lower(get(cax, 'NextPlot'));
    hold_state = ishold(cax);
    
    % get x-axis text color so grid is in same color
    tc = get(cax, 'XColor');
    ls = get(cax, 'GridLineStyle');
    
    % Hold on to current Text defaults, reset them to the
    % Axes' font attributes so tick marks use them.
    fAngle = get(cax, 'DefaultTextFontAngle');
    fName = get(cax, 'DefaultTextFontName');
    fSize = get(cax, 'DefaultTextFontSize');
    fWeight = get(cax, 'DefaultTextFontWeight');
    fUnits = get(cax, 'DefaultTextUnits');
    set(cax, ...
        'DefaultTextFontAngle', get(cax, 'FontAngle'), ...
        'DefaultTextFontName', get(cax, 'FontName'), ...
        'DefaultTextFontSize', get(cax, 'FontSize'), ...
        'DefaultTextFontWeight', get(cax, 'FontWeight'), ...
        'DefaultTextUnits', 'data');
    
    % only do grids if hold is off
    if ~hold_state
        
        % make a radial grid
        hold(cax, 'on');
        % ensure that Inf values don't enter into the limit calculation.
        arho = abs(rho(:));
        maxrho = max(arho(arho ~= Inf));
        hhh = line([-maxrho, -maxrho, maxrho, maxrho], [-maxrho, maxrho, maxrho, -maxrho], 'Parent', cax);
        set(cax, 'DataAspectRatio', [1, 1, 1], 'PlotBoxAspectRatioMode', 'auto');
        v = [get(cax, 'XLim') get(cax, 'YLim')];
        ticks = sum(get(cax, 'YTick') >= 0);
        delete(hhh);
        % check radial limits and ticks
        rmin = 0;
        rmax = v(4);
        rticks = max(ticks - 1, 2);
        if rticks > 5   % see if we can reduce the number
            if rem(rticks, 2) == 0
                rticks = rticks / 2;
            elseif rem(rticks, 3) == 0
                rticks = rticks / 3;
            end
        end
        
        % define a circle
        th = 0 : pi / (36*4) : 2 * pi;
        xunit = cos(th);
        yunit = sin(th);
        % now really force points on x/y axes to lie on them exactly
        inds = 1 : (length(th) - 1) / 4 : length(th);
        xunit(inds(2 : 2 : 4)) = zeros(2, 1);
        yunit(inds(1 : 2 : 5)) = zeros(3, 1);
        % plot background if necessary
        if ~ischar(get(cax, 'Color'))
            patch('XData', xunit * rmax, 'YData', yunit * rmax, ...
                'EdgeColor', tc, 'FaceColor', get(cax, 'Color'), ...
                'HandleVisibility', 'off', 'Parent', cax);
        end
        
        % draw radial circles
        c82 = cos(85 * pi / 180);
        s82 = sin(85 * pi / 180);
        rinc = (rmax - rmin) / rticks;
        for i = (rmin + rinc) : rinc : rmax
            hhh = line(xunit * i, yunit * i, 'LineStyle', ls, 'Color', tc, 'LineWidth', 1, ...
                'HandleVisibility', 'off', 'Parent', cax);
            %text((i + rinc / 20) * c82, (i + rinc / 20) * s82, ...
            %    ['  ' num2str(i)], 'VerticalAlignment', 'bottom', ...
            %    'HandleVisibility', 'off', 'Parent', cax);
        end
        set(hhh, 'LineStyle', '-'); % Make outer circle solid
        
        
% plot spokes
    nOri = 24;
    th = ((1:(nOri/2))+(nOri/4))*2*pi/nOri;
    cst = cos(th); snt = sin(th);
    cs = [-cst; cst];
    sn = [-snt; snt];
    line(rmax*cs,rmax*sn,'linestyle',ls,'color',tc,'linewidth',1,...
         'handlevisibility','off','parent',cax)

% annotate spokes in degrees
    rt = 1.1*rmax;
    for i = 1:length(th)
        if mod(i,2)==0
            text(rt*cst(i),rt*snt(i),int2str(-i*(360/nOri)),...
                'horizontalalignment','center',...
                'handlevisibility','off','parent',cax);
        end
        if i == length(th)
            loc = 0;
        else
            loc = 180+i*(360/nOri) ;
            if loc>180
                loc=loc-360;
            end
        end
        loc = -loc;
        loc = int2str(loc);
        if mod(i,2)==0
            text(-rt*cst(i),-rt*snt(i),loc,'horizontalalignment','center',...
                'handlevisibility','off','parent',cax)
        end
    end

%{        
        % plot spokes
        th = (1 : 6) * 2 * pi / 12;
        cst = cos(th);
        snt = sin(th);
        cs = [-cst; cst];
        sn = [-snt; snt];
        line(rmax * cs, rmax * sn, 'LineStyle', ls, 'Color', tc, 'LineWidth', 1, ...
            'HandleVisibility', 'off', 'Parent', cax);
        
        % annotate spokes in degrees
        rt = 1.1 * rmax;
        for i = 1 : length(th)
            text(rt * cst(i), rt * snt(i), int2str(i * 30),...
                'HorizontalAlignment', 'center', ...
                'HandleVisibility', 'off', 'Parent', cax);
            if i == length(th)
                loc = int2str(0);
            else
                loc = int2str(180 + i * 30);
            end
            text(-rt * cst(i), -rt * snt(i), loc, 'HorizontalAlignment', 'center', ...
                'HandleVisibility', 'off', 'Parent', cax);
        end
        %}
        
        % set view to 2-D
        view(cax, 2);
        % set axis limits
        axis(cax, rmax * [-1, 1, -1.15, 1.15]);
    end
    
    % Reset defaults.
    set(cax, ...
        'DefaultTextFontAngle', fAngle , ...
        'DefaultTextFontName', fName , ...
        'DefaultTextFontSize', fSize, ...
        'DefaultTextFontWeight', fWeight, ...
        'DefaultTextUnits', fUnits );
    
    % transform data to Cartesian coordinates.
    xx = rho .* cos(theta);
    yy = rho .* sin(theta);
    
    % plot data on top of grid
    %{
    if strcmp(line_style, 'auto')
        q = plot(xx, yy, 'Parent', cax);
    else
        q = plot(xx, yy, line_style, 'Parent', cax);
    end
    %}
    q = fill(xx, yy, [0 0 0.7]);
    %q = plot(xx, yy, 'b');
    
        for i = (rmin + rinc) : rinc : rmax
            %hhh = line(xunit * i, yunit * i, 'LineStyle', ls, 'Color', tc, 'LineWidth', 1, ...
            %    'HandleVisibility', 'off', 'Parent', cax);
            text((i + rinc / 20) * c82, (i + rinc / 20) * s82, ...
                ['  ' num2str(i)], 'VerticalAlignment', 'bottom', ...
                'HandleVisibility', 'off', 'Parent', cax);
        end        
    
    
    if nargout == 1
        hpol = q;
    end
    
    if ~hold_state
        set(cax, 'DataAspectRatio', [1, 1, 1]), axis(cax, 'off');
        set(cax, 'NextPlot', next);
    end
    set(get(cax, 'XLabel'), 'Visible', 'on');
    set(get(cax, 'YLabel'), 'Visible', 'on');
    
    if ~isempty(q) && ~isdeployed
        makemcode('RegisterHandle', cax, 'IgnoreHandle', q, 'FunctionName', 'polar');
    end
end
