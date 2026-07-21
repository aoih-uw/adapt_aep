function apply_tufte()
% Apply Tufte-style formatting to every open figure.
% Call once, just before your exportgraphics loop.
figs = findall(0, 'Type', 'figure');
for f = 1:numel(figs)
    set(figs(f), 'Color', 'w');
    axs = findall(figs(f), 'Type', 'axes');
    for a = 1:numel(axs)
        ax = axs(a);
        box(ax, 'off');                         % remove top/right spines
        set(ax, 'TickDir', 'out', ...           % ticks point outward
            'LineWidth', 0.75, ...              % thin axes
            'Color', 'none', ...                % no background fill
            'FontName', 'Inter', ...
            'XColor', [0.2 0.2 0.2], ...
            'YColor', [0.2 0.2 0.2]);
        ax.TickLength = [0.02 0.02];
    end
    lgs = findall(figs(f), 'Type', 'legend');
    for l = 1:numel(lgs)
        lgs(l).Box = 'off';                     % remove legend frame
    end

    % Deduplicate shared axis labels in tiled layouts
    tls = findall(figs(f), 'Type', 'tiledlayout');
    for k = 1:numel(tls)
        tax = findall(tls(k).Children, 'flat', 'Type', 'axes');
        if numel(tax) < 2, continue; end
        ncol = tls(k).GridSize(2);
        tile = arrayfun(@(a) a.Layout.Tile, tax);
        row  = ceil(tile / ncol);
        col  = mod(tile - 1, ncol) + 1;
        xl = arrayfun(@(a) string(a.XLabel.String), tax);
        yl = arrayfun(@(a) string(a.YLabel.String), tax);
        for a = 1:numel(tax)
            if all(xl == xl(1)) && row(a) < max(row)
                tax(a).XLabel.String = '';
            end
            if all(yl == yl(1)) && col(a) > 1
                tax(a).YLabel.String = '';
            end
        end
    end

    % Font sizes: only for non-tiledlayout figures
    if isempty(tls)
        txt = findall(figs(f), '-property', 'FontSize');
        sz  = get(txt, 'FontSize');
        if ~iscell(sz), sz = {sz}; end
        for t = 1:numel(txt)
            txt(t).FontSize = sz{t} * 1.1;      % all text 1.1x bigger
        end
        for a = 1:numel(axs)
            axs(a).Title.FontSize = 14;         % title fixed at 14 pt
        end
    end
end
end