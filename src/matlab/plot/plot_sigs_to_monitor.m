function plot_sigs_to_monitor(data_type, ex, app, N_samples, N_trials, N_channels)
fs = ex.info.recording.sampling_rate_hz;
color_names = {'red','blue','orange','teal','green','yellow','purple','pink','brown','grey'};
time_s = (0:N_samples-1) / fs;

if strcmp(data_type, 'raw')
    iblock = ex.counter.iblock;
    hydrophone_data = ex.raw(iblock).hydrophone_mV;
    electrode_data = ex.raw(iblock).electrodes_microV;
end

max_plot_points = 2000;
plot_idx = 1:max(1, ceil(N_samples/max_plot_points)):N_samples;
time_s_ds = time_s(plot_idx);

% --- Hydrophone ---
ax = app.UIAxes_hydrophone;
y = hydrophone_data(randperm(N_trials,1), plot_idx);
h = ax.UserData;
if isempty(h) || ~isfield(h,'line') || ~isvalid(h.line)
    h.line = plot(ax, time_s_ds, y, 'Color', tableau_10('purple'), 'LineWidth', 1.5);
    ax.UserData = h;
else
    set(h.line, 'XData', time_s_ds, 'YData', y);
end
if isempty(ex.block(iblock).hydrophone) || isnan(isempty(ex.block(iblock).hydrophone))
    title(ax, sprintf('Hydrophone'));
else
    title(ax, sprintf('Hydrophone; Stimulus amplitude: %.0f dB SPL', ex.block(iblock).hydrophone.stimulus_rms));
end

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

% --- Electrode channels ---
electrode_axes = {app.UIAxes_ch1, app.UIAxes_ch2, app.UIAxes_ch3, app.UIAxes_ch4};
data_mean_all = zeros(N_channels, numel(plot_idx));
for ch = 1:N_channels
    ax = electrode_axes{ch};
    seg = electrode_data(:, plot_idx, ch);
    data_mean = mean(seg, 1);
    data_std  = std(seg, 0, 1);
    data_mean_all(ch,:) = data_mean;
    color = tableau_10(color_names{mod(ch-1,10)+1});

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
    end
end

pad = max(range(data_mean_all(:)) * 0.2, eps);
lo = min(data_mean_all(:),[],'omitnan');
hi = max(data_mean_all(:),[],'omitnan');
linkaxes([electrode_axes{:}], 'xy');
safe_ylim(electrode_axes{1}, lo - pad, hi + pad);
drawnow limitrate
end

function update_line(ax, x, y, color)
h = ax.UserData;
if isempty(h) || ~isfield(h,'line') || ~isvalid(h.line)
    h.line = plot(ax, x, y, 'o-', 'Color', color, 'MarkerFaceColor', color);
    ax.UserData = h;
else
    set(h.line, 'XData', x, 'YData', y);
end
end

function val = get_field_or_nan(b, field)
if isfield(b, 'hydrophone') && isfield(b.hydrophone, field)
    val = b.hydrophone.(field);
else
    val = NaN;
end
end

function update_errorbar(ax, x, y, err, color)
h = ax.UserData;
if isempty(h) || ~isfield(h,'line') || ~isvalid(h.line)
    h.line = errorbar(ax, x, y, err, 'o-', 'Color', color, 'MarkerFaceColor', color);
    ax.UserData = h;
else
    set(h.line, 'XData', x, 'YData', y, 'YNegativeDelta', err, 'YPositiveDelta', err);
end
end