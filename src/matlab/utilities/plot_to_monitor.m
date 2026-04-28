function plot_to_monitor(data_type, ex,app, N_samples, N_trials, N_channels)
if strcmp(data_type, 'health')
    ihealth = ex.counter.health;
    hydrophone_data = ex.health(ihealth).hydrophone_mV;
    electrode_data = ex.health(ihealth).electrodes_microV;
elseif strcmp(data_type, 'raw')
    iblock = ex.counter.iblock;
    hydrophone_data = ex.raw(iblock).hydrophone_mV;
    electrode_data = ex.raw(iblock).electrodes_microV;
end
%% Plot signals
fs = ex.info.recording.sampling_rate_hz; 
color_names = {'blue', 'orange', 'red', 'teal', 'green', 'yellow', 'purple', 'pink', 'brown', 'grey'};
time_s = (0:N_samples-1) / fs;

% Downsample for plotting
max_plot_points = 2000; % Adjust as needed
if N_samples > max_plot_points
    ds_factor = floor(N_samples / max_plot_points);
    plot_idx = 1:ds_factor:N_samples;
else
    plot_idx = 1:N_samples;
end
time_s_ds = time_s(plot_idx);

% Hydrophone
cla(app.UIAxes_hydrophone);
hold(app.UIAxes_hydrophone, 'on');
plot(app.UIAxes_hydrophone, time_s_ds, hydrophone_data(randperm(N_trials,1), plot_idx), ...
    'Color', tableau_10('purple'), 'LineWidth', 1.5);
hold(app.UIAxes_hydrophone, 'off');
title(app.UIAxes_hydrophone, 'Hydrophone');

% Plot electrode channels
electrode_axes = {app.UIAxes_ch1, app.UIAxes_ch2, app.UIAxes_ch3, app.UIAxes_ch4};

for ch = 1:N_channels
    cla(electrode_axes{ch});
    hold(electrode_axes{ch}, 'on');

    data_mean = mean(squeeze(electrode_data(:, plot_idx, ch)), 1);
    data_std = std(squeeze(electrode_data(:, plot_idx, ch)), 0, 1);

    color = tableau_10(color_names{mod(ch-1, 10) + 1});

    fill(electrode_axes{ch}, [time_s_ds, fliplr(time_s_ds)], ...
         [data_mean + data_std, fliplr(data_mean - data_std)], ...
         color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');

    plot(electrode_axes{ch}, time_s_ds, data_mean, 'Color', color, 'LineWidth', 1.5);

    hold(electrode_axes{ch}, 'off');
end

% Set y lim
data_mean_all = mean(electrode_data(:, plot_idx, :), 1);
pad = range(data_mean_all(:)) * 0.2;
ylim(electrode_axes{1}, [min(data_mean_all(:)) - pad, max(data_mean_all(:)) + pad]);

linkaxes([electrode_axes{:}], 'xy');

drawnow