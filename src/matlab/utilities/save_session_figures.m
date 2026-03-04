function save_session_figures(ex, folder, app)
% Save modeling plots (Elbow, threshold and slope estimation plots) from
% Adapt_AEP interface

figures_folder = fullfile(folder, 'figures');
fig_prefix = sprintf('%s', ex.info.animal.filename_root);

axes_list = {app.UIAxes_model, app.UIAxes_thresh_est, app.UIAxes_slope_est};
suffixes = {'_elbow', '_thresh_est', '_slope_est'};

for i = 1:3
    if isempty(get(axes_list{i}, 'Children')), continue; end
    f = figure('Visible', 'off');
    ax_new = axes(f);
    copyobj(get(axes_list{i}, 'Children'), ax_new);
    ax_new.XLim = axes_list{i}.XLim;
    ax_new.YLim = axes_list{i}.YLim;
    ax_new.XLabel.String = axes_list{i}.XLabel.String;
    ax_new.YLabel.String = axes_list{i}.YLabel.String;
    ax_new.Title.String = axes_list{i}.Title.String;
    ax_new.XGrid = axes_list{i}.XGrid;
    ax_new.YGrid = axes_list{i}.YGrid;
    savefig(f, fullfile(figures_folder, [fig_prefix suffixes{i} '.fig']));
    print(f, fullfile(figures_folder, [fig_prefix suffixes{i} '.png']), '-dpng', '-r150');
    close(f);
end
end


