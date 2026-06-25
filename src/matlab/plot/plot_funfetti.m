function plot_funfetti(ex, iblock, fs, app)
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

% fft_ax
delete(allchild(fft_ax)); hold(fft_ax, 'on')
for ic = 1:n_ch
    sig = ex.raw(iblock).electrodes_microV(:,:,channels(ic));
    [~, f, fft_val] = calc_fft(mean(sig, 1), fs);
    [~, ~, fft_std] = calc_fft(std(sig, [], 1), fs);
    c = colors{ic};

    % Get 2f bin (do this on the FULL vector, before trimming)
    [~, loc_2f] = min(abs(f - target_freq));
    my_2f(ic,n_points+1)     = fft_val(loc_2f);
    my_2f_std(ic,n_points+1) = fft_std(loc_2f);

    % Trim to the display window
    m  = f <= target_freq*2;
    ff = f(m);  vv = fft_val(m);  ss = fft_std(m);

    fill(fft_ax, [ff, fliplr(ff)], [vv + ss, fliplr(vv - ss)], ...
        c, 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(fft_ax, ff, vv, 'Color', c, 'LineWidth', 1.5);
end
xlabel(fft_ax, 'Frequency (Hz)');
ylabel(fft_ax, 'Magnitude (\muV)');
title(fft_ax, 'Live FFT Monitor');
xlim(fft_ax, [0, target_freq*2]);
xline(fft_ax, target_freq,'HandleVisibility', 'off');
legend(fft_ax,channel_name)
hold(fft_ax, 'off')

% bin_ax
cla(bin_ax); hold(bin_ax,'on')
for ic = 1:n_ch
errorbar(bin_ax, my_2f(ic,:), my_2f_std(ic,:), '-o', ...
    'Color', colors{ic}, 'MarkerFaceColor', colors{ic});
end
hold(bin_ax, 'off');
xlabel(bin_ax, 'Iteration');
ylabel(bin_ax, '2f Magnitude (\muV)');
title(bin_ax, sprintf('2f Response Tracking @ %g Hz', target_freq));
end