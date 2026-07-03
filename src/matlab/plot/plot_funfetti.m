function plot_funfetti(ex, iblock, fs, app)
%% Plot the current block's 2f response magnitude persistently throughout experiment
% Assign Variables
persistent my_2f my_2f_std
if iblock == 1
    my_2f = []; my_2f_std = [];
end
n_points = size(my_2f,2);
channels    = [2, 3, 4];
channel_name = {'2 mm', '4 mm', 'Skin'};
target_freq = ex.info.stimulus.frequency_hz * 2;
fft_ax = app.UIAxes_live_fft;
bin_ax = app.UIAxes_funfetti;
colors = {tableau_10('blue'), tableau_10('orange'), tableau_10('green')};
n_ch   = numel(channels);
target_freq_range = ex.info.stimulus.range_2f_hz;

% fft_ax
delete(allchild(fft_ax)); hold(fft_ax, 'on')
for ic = 1:n_ch
    sig = ex.raw(iblock).electrodes_microV(:,:,channels(ic));
    c = colors{ic};

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

    mean_target_bin_mag_vec = ...
    find_fft_bins(target_freq, target_freq_range, fft_val, freq_vec);

    std_target_bin_mag_vec = ...
    find_fft_bins(target_freq, target_freq_range, fft_std, freq_vec);

    % Get 2f bin on the full vector, before trimming
    my_2f(ic,n_points+1)     = mean_target_bin_mag_vec;
    my_2f_std(ic,n_points+1) = std_target_bin_mag_vec;

    % Trim to display window
    my_mask  = freq_vec <= target_freq*2;
    ff = freq_vec(my_mask);  vv = fft_val(my_mask);  ss = fft_std(my_mask);

    fill(fft_ax, [ff, fliplr(ff)], [vv+ss, fliplr(vv-ss)], ...
        c, 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(fft_ax, ff, vv, 'Color', c, 'LineWidth', 1.5);
end
xlabel(fft_ax, 'Frequency (Hz)');
ylabel(fft_ax, 'Magnitude (\muV)');
title(fft_ax, 'Live FFT Monitor');
xlim(fft_ax, [0, target_freq*2]);
xline(fft_ax, target_freq,'HandleVisibility', 'off');
legend(fft_ax, channel_name) 
hold(fft_ax, 'off')

% bin_ax
cla(bin_ax); hold(bin_ax,'on')
for ic = 1:n_ch
errorbar(bin_ax, my_2f(ic,:), my_2f_std(ic,:), '-o', ...
    'Color', colors{ic}, 'MarkerFaceColor', colors{ic});
end
legend(bin_ax,channel_name,'Location','best')
hold(bin_ax, 'off');
xlabel(bin_ax, 'Iteration');
ylabel(bin_ax, '2f Magnitude (\muV)');
title(bin_ax, sprintf('2f Response Tracking @ %g Hz', target_freq));
end