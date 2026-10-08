function plot_sigs_to_monitor(data_type, ex, app, N_samples, N_trials)
% Assign vars
fs = ex.info.DAC.sampling_rate_hz;
colors = ex.info.colors;
time_s = (0:N_samples-1) / fs;

% Setup data variables
if strcmp(data_type, 'raw')
    iblock = ex.counter.iblock;
    hydrophone_data = ex.raw(iblock).hydrophone_mV;
    if ex.test_accel % Setup for accelerometer
        my_chans = ~ismember(ex.info.DAC.input_channel_names, {'Hydrophone', 'Loopback'});
        ch_names = ex.info.DAC.input_channel_names(my_chans);
        N_channels = sum(my_chans);
        N_acc = size(ex.raw(iblock).accelerometer_mV,3);
        sensor_data = cat(3, ex.raw(iblock).accelerometer_mV, ex.raw(iblock).electrodes_microV);
    else % Set up for electrode signals
        ch_names = ex.info.electrodes.names{1};
        N_channels = ex.info.electrodes.n_channels;
        N_acc = 0;
        sensor_data = ex.raw(iblock).electrodes_microV;
    end
end

% Downsampling variables
max_plot_points = 2000;
plot_idx = 1:max(1, ceil(N_samples/max_plot_points)):N_samples;
time_s_ds = time_s(plot_idx);

%% Hydrophone
ax = app.UIAxes_hydrophone;
y = hydrophone_data(randperm(N_trials,1), plot_idx);
h = ax.UserData;
if isempty(h) || ~isfield(h,'line') || ~isvalid(h.line)
    h.line = plot(ax, time_s_ds, y, 'Color', tableau_10('purple'), 'LineWidth', 1.5);
    ax.UserData = h;
else
    set(h.line, 'XData', time_s_ds, 'YData', y);
end
if isnan(ex.block(iblock).hydrophone.stimulus_rms)
    title(ax, sprintf('Hydrophone'));
else
    title(ax, sprintf('Hydrophone; Stimulus amplitude: %.0f dB SPL', ex.block(iblock).hydrophone.stimulus_rms));
end

% Get Data
if strcmp(data_type, 'raw')
    rms_vec    = arrayfun(@(b) get_field_or_nan(b, 'tank_nf_rms'),            ex.block(1:iblock));
    nf_mad_vec = arrayfun(@(b) get_field_or_nan(b, 'tank_nf_rms_mad'),        ex.block(1:iblock));
    snr_vec    = arrayfun(@(b) get_field_or_nan(b, 'stim_ON_snr_median'), ex.block(1:iblock));
    snr_mad_vec = arrayfun(@(b) get_field_or_nan(b, 'stim_ON_snr_mad'),   ex.block(1:iblock));
    update_errorbar(app.UIAxes_tank_noise_floor, 1:iblock, rms_vec, nf_mad_vec,  tableau_10('green'));
    update_errorbar(app.UIAxes_signal_SNR,       1:iblock, snr_vec, snr_mad_vec, tableau_10('orange'));
    pad = 0.5;
    safe_ylim(app.UIAxes_tank_noise_floor, min(rms_vec-nf_mad_vec,[],'omitnan')-pad, max(rms_vec+nf_mad_vec,[],'omitnan')+pad);
    safe_ylim(app.UIAxes_signal_SNR,       min(snr_vec-snr_mad_vec,[],'omitnan')-pad, max(snr_vec+snr_mad_vec,[],'omitnan')+pad);
end

%% Sensor channels
sensor_axes = {app.UIAxes_ch1, app.UIAxes_ch2, app.UIAxes_ch3, app.UIAxes_ch4};
data_mean_all = zeros(N_channels, numel(plot_idx));
for ch = 1:N_channels
    ax = sensor_axes{ch}; 
    title(ax, ch_names{ch});
    if ch <= N_acc, ylabel(ax, 'mV'); else, ylabel(ax, '\muV'); end
    seg = sensor_data(:, plot_idx, ch);
    data_mean = mean(seg, 1);
    data_std  = std(seg, 0, 1);
    data_mean_all(ch,:) = data_mean;
    color = colors{mod(ch-1,10)+1};

    h = ax.UserData;
    if isempty(h) || ~isfield(h,'line') || ~isvalid(h.line)
        h.fill = fill(ax, [time_s_ds, fliplr(time_s_ds)], ...
            [data_mean+data_std, fliplr(data_mean-data_std)], ...
            color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        hold(ax, 'on');
        h.line = plot(ax, time_s_ds, data_mean, 'Color', color, 'LineWidth', 1.5);
        xlim(ax, [min(time_s_ds), max(time_s_ds)]);
        ax.UserData = h;
    else
        set(h.fill, 'XData', [time_s_ds, fliplr(time_s_ds)], ...
            'YData', [data_mean+data_std, fliplr(data_mean-data_std)]);
        set(h.line, 'XData', time_s_ds, 'YData', data_mean);
        xlim(ax, [min(time_s_ds), max(time_s_ds)]);

    end
end

% Set axes limits
linkaxes([sensor_axes{:}], 'off');
groups = {1:N_acc, N_acc+1:N_channels};
for g = 1:numel(groups)
    idx = groups{g};
    if isempty(idx), continue; end
    vals = data_mean_all(idx,:);
    pad = max(range(vals(:)) * 0.2, eps);
    linkaxes([sensor_axes{idx}], 'y');
    safe_ylim(sensor_axes{idx(1)}, min(vals(:),[],'omitnan') - pad, max(vals(:),[],'omitnan') + pad);
end
drawnow limitrate
end

%% Local functions
function update_errorbar(ax, x, y, err, color)
h = ax.UserData;
if isempty(h) || ~isfield(h,'line') || ~isvalid(h.line)
    h.line = errorbar(ax, x, y, err, 'o-', 'Color', color, 'MarkerFaceColor', color);
    ax.UserData = h;
else
    set(h.line, 'XData', x, 'YData', y, 'YNegativeDelta', err, 'YPositiveDelta', err);
end
end

function val = get_field_or_nan(b, field)
if isfield(b, 'hydrophone') && isfield(b.hydrophone, field)
    val = b.hydrophone.(field);
else
    val = NaN;
end
end