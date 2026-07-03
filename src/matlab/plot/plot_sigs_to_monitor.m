function plot_sigs_to_monitor(data_type, ex,app, N_samples, N_trials, N_channels)
%% Plot hydrophone and electrode signals to the adapt_aep GUI
% Assign variables
fs = ex.info.recording.sampling_rate_hz;
color_names = {'red', 'blue', 'orange', 'teal', 'green', 'yellow', 'purple', 'pink', 'brown', 'grey'};
time_s = (0:N_samples-1) / fs;

% Extract Data
if strcmp(data_type, 'raw')
    iblock = ex.counter.iblock;
    hydrophone_data = ex.raw(iblock).hydrophone_mV;
    electrode_data = ex.raw(iblock).electrodes_microV;
end

% Downsample for plotting
max_plot_points = 2000; % Adjust as needed
if N_samples > max_plot_points
    ds_factor = 10;
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
title(app.UIAxes_hydrophone, sprintf('Hydrophone; Stimulus amplitude: %.0f dB SPL', ex.block(iblock).hydrophone.stim_ON_rms_dB_spl));

if strcmp(data_type, 'raw')
    cla(app.UIAxes_tank_noise_floor)
    cla(app.UIAxes_signal_SNR)
    rms_vec = arrayfun(@(b) b.hydrophone.stim_OFF_rms_dB_spl, ex.block(1:iblock));
    snr_vec = arrayfun(@(b) b.hydrophone.stim_ON_snr,        ex.block(1:iblock));

    plot(app.UIAxes_tank_noise_floor, rms_vec, 'o-', 'Color', tableau_10('green'), 'MarkerFaceColor', tableau_10('green'));
    plot(app.UIAxes_signal_SNR,       snr_vec, 'o-', 'Color', tableau_10('orange'), 'MarkerFaceColor', tableau_10('orange'));

    pad = 0.5;  % or whatever margin makes sense
    safe_ylim(app.UIAxes_tank_noise_floor, min(rms_vec,[],'omitnan')-pad, max(rms_vec,[],'omitnan')+pad);
    safe_ylim(app.UIAxes_signal_SNR,       min(snr_vec,[],'omitnan')-pad, max(snr_vec,[],'omitnan')+pad);end

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
    xlim(electrode_axes{ch},[min(time_s_ds),max(time_s_ds)])
    hold(electrode_axes{ch}, 'off');
end

% Set y lim
data_mean_all = mean(electrode_data(:, plot_idx, :), 1);
pad = range(data_mean_all(:)) * 0.2;
pad = max(pad,eps);
linkaxes([electrode_axes{:}], 'xy');
lo = min(data_mean_all(:),[],'omitnan');
hi = max(data_mean_all(:),[],'omitnan');
linkaxes([electrode_axes{:}], 'xy');
safe_ylim(electrode_axes{1}, lo - pad, hi + pad);

drawnow
end


