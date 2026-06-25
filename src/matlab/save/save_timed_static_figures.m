function save_timed_static_figures(ex,app,folder)
figures_folder = fullfile(folder, 'figures');
fig_prefix = sprintf('%s_%ddBSPL', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl);
axes_list = {app.UIAxes_funfetti, app.UIAxes_live_fft, app.UIAxes_health};
names = {'funfetti', 'live_fft', 'health'};
for i = 1:numel(axes_list)
    f = figure('Visible','on','Units','normalized','OuterPosition',[0 0 1 1]);
    ax = copyobj(axes_list{i}, f);
    set(ax,'Units','normalized','Position',[0.1 0.1 0.85 0.85]);
    drawnow;
    save_with_unique_name(f, fullfile(figures_folder, names{i}), [fig_prefix '_' names{i}]);
    close(f);
end
end

function save_with_unique_name(f, out_dir, fname)
if ~exist(out_dir, 'dir'), mkdir(out_dir); end
base = fullfile(out_dir, fname);
name = base; n = 1;
while exist([name '.fig'], 'file') || exist([name '.png'], 'file')
    n = n + 1;
    name = sprintf('%s_%d', base, n);
end
savefig(f, [name '.fig']);
print(f, [name '.png'], '-dpng', '-r150');
end