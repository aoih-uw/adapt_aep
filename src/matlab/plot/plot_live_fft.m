function plot_live_fft(ex, iblock, fs, app)
%% Plot the current block's 2f response magnitude persistently throughout experiment
% Plots live fft AND funfetti (if non mixed mode nor testing with accelerometer)
% Currently only used for timed experiments

%% Assign Variables
persistent my_2f my_2f_std
% Reset persistent variables
if strcmp(app.DropDown_test_mode.Value, 'Mixed freqs')
    if  ex.counter.ischedule == 1
        my_2f = []; my_2f_std = [];
    end
elseif  strcmp(app.DropDown_test_mode.Value, 'Timed')
    if ex.counter.grand_iblock == 1
        my_2f = []; my_2f_std = [];
    end
else
    if iblock == 1
        my_2f = []; my_2f_std = [];
    end
end

% Assign variables
% Get current frequency idx
freq_idx = get_current_freq_idx(ex);
stim_freq = ex.info.stimulus(freq_idx).frequency_hz;
target_freq = ex.info.stimulus(freq_idx).frequency_hz * 2;
target_freq_range = ex.info.stimulus(freq_idx).range_2f_hz;
colors = ex.info.colors;

n_points = size(my_2f,2);
if ex.test_accel
    my_chans = ~ismember(ex.info.DAC.input_channel_names, {'Hydrophone', 'Loopback'});
    channels = 1:sum(my_chans);
    channel_name = {ex.info.DAC.input_channel_names(find(my_chans))};
else
    channels    = 1:ex.info.electrodes.n_channels;
    channel_name = ex.info.electrodes.names;
end
% Unpack
channel_name = channel_name{1};

% Set axes
fft_ax = app.UIAxes_live_fft;
bin_ax = app.UIAxes_funfetti;

% fft_ax
% Clear axes
if ex.test_accel
    yyaxis(fft_ax, 'right'); delete(allchild(fft_ax)); hold(fft_ax, 'on')
    yyaxis(fft_ax, 'left');
end
delete(allchild(fft_ax)); hold(fft_ax, 'on')
accel_names = ex.info.accel.chan_order;

% Loop through channels
for ic = 1:numel(channels)
    c = colors{ic};
    % Get signal
    if ismember(channel_name{ic}, accel_names)
        yyaxis(fft_ax, 'right');
        sig = ex.raw(iblock).accelerometer_mV(:,:,strcmp(accel_names, channel_name{ic}));
    else
        if ex.test_accel, yyaxis(fft_ax, 'left'); end
        sig = ex.raw(iblock).electrodes_microV(:,:,sum(~ismember(channel_name(1:ic), accel_names)));
    end

    % Compute per-trial FFTs, then derive mean spectrum and per-bin std
    n_trials = size(sig, 1);
    for it = 1:n_trials
        [~, freq_vec, fft_vals] = calc_fft(sig(it,:), fs);
        if it == 1
            trial_ffts = zeros(n_trials, numel(freq_vec));
        end
        trial_ffts(it,:) = fft_vals;
    end
    fft_val = mean(trial_ffts, 1);
    fft_std = std(trial_ffts, [], 1);

    [mean_target_bin_mag_vec, bin_loc] = ...
        find_fft_bins(target_freq, target_freq_range, fft_val, freq_vec);

    std_target_bin_mag_vec = fft_std(bin_loc);

    % Get 2f bin on the full vector, before trimming
    my_2f(ic,n_points+1)     = mean_target_bin_mag_vec;
    my_2f_std(ic,n_points+1) = std_target_bin_mag_vec;

    % Trim to display window
    my_mask  = freq_vec >= (stim_freq-(stim_freq/2)) & freq_vec <= target_freq*2;
    ff = freq_vec(my_mask);  vv = fft_val(my_mask);  ss = fft_std(my_mask);
    ff = ff(:).'; vv = vv(:).'; ss = ss(:).';

    fill(fft_ax, [ff, fliplr(ff)], [vv+ss, fliplr(vv-ss)], ...
        c, 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(fft_ax, ff, vv, 'Color', c, 'LineWidth', 1.5, 'DisplayName', channel_name{ic});
    ylim(fft_ax, 'auto')
end

% Formatting
xlabel(fft_ax, 'Frequency (Hz)');
if ex.test_accel
    yyaxis(fft_ax, 'left');  ylabel(fft_ax, 'Electrode magnitude (\muV)');
    yyaxis(fft_ax, 'right'); ylabel(fft_ax, 'Accel magnitude (mV)');
else
    ylabel(fft_ax, 'Electrode magnitude (\muV)');
end
title(fft_ax, 'Live FFT Monitor');
xlim(fft_ax, [(stim_freq-(stim_freq/2)), target_freq*2]);
xline(fft_ax, target_freq,'HandleVisibility', 'off');
legend(fft_ax)
hold(fft_ax, 'off')

% Plot funfetti if it is NOT Mixed freqs mode and NOT testing with an
% accelerometer
if ~strcmp(app.DropDown_test_mode.Value, 'Mixed freqs') && ~ex.test_accel    % bin_ax
    cla(bin_ax); hold(bin_ax,'on')
    for ic = 1:numel(channels)
        errorbar(bin_ax, my_2f(ic,:), my_2f_std(ic,:), '-o', ...
            'Color', colors{ic}, 'MarkerFaceColor', colors{ic});
    end
    legend(bin_ax,channel_name,'Location','best')
    hold(bin_ax, 'off');
    xlabel(bin_ax, 'Iteration');
    ylabel(bin_ax, '2f Magnitude (\muV)');
    title(bin_ax, sprintf('2f Response Tracking @ %g Hz', target_freq));
end
end