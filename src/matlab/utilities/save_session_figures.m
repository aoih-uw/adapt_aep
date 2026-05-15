function save_session_figures(ex, folder, app)
% Save modeling plots (Elbow, threshold and slope estimation plots) from

% Adapt_AEP interface
figures_folder = fullfile(folder, 'figures');
fig_prefix = sprintf('%s', ex.info.animal.filename_root);
axes_list = {app.UIAxes_model, app.UIAxes_model_2, app.UIAxes_model_3, app.UIAxes_thresh_est, app.UIAxes_slope_est};
suffixes = {'_GP', '_expo', '_piece', '_thresh_est', '_slope_est'};
subfolders = {'GP', 'expo', 'piece', 'thresh_est', 'slope_est'};

for i = 1:length(suffixes)
    if isempty(get(axes_list{i}, 'Children')), continue; end
    out_dir = fullfile(figures_folder, subfolders{i});
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end
    f = figure('Visible', 'off', 'Units', 'normalized', 'Position', [0 0 1 1], ...
           'CreateFcn', 'set(gcbo,''Visible'',''on'')');
    ax_new = axes(f);
    copyobj(get(axes_list{i}, 'Children'), ax_new);
    ax_new.XLim = axes_list{i}.XLim;
    ax_new.YLim = axes_list{i}.YLim;
    ax_new.XLabel.String = axes_list{i}.XLabel.String;
    ax_new.YLabel.String = axes_list{i}.YLabel.String;
    ax_new.Title.String = axes_list{i}.Title.String;
    savefig(f, fullfile(out_dir, [fig_prefix suffixes{i} '.fig']));
    print(f, fullfile(out_dir, [fig_prefix suffixes{i} '.png']), '-dpng', '-r150');
    close(f);
end
end