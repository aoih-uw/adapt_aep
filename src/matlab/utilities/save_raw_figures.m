function save_raw_figures(ex, folder)
iamp = ex.counter.iamp;
if ex.test == 1
    double_freq_hz  = ex.info.stimulus.frequency_hz;
else
    double_freq_hz  = ex.info.stimulus.frequency_hz*2;
end
diffs_fft = ex.fft.diffs;
stim_ON_fft = ex.fft.stim_ON;
freq_vec = ex.fft.freq_vec;
num_trials = size(diffs_fft,1);

figures_folder = fullfile(folder, 'figures');
fig_prefix = sprintf('%s_%ddBSPL', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl);

% Mean Difference FFT
f1 = figure('Visible', 'off');
mean_fft = mean(diffs_fft,1);
std_fft = std(diffs_fft,0,1);

fill([freq_vec fliplr(freq_vec)], [mean_fft+std_fft fliplr(mean_fft-std_fft)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold on;
plot(freq_vec, mean_fft, 'Color', tableau_10('blue'), 'LineWidth', 1.5);
xlim([(double_freq_hz-(double_freq_hz/1.1))*2, (double_freq_hz+(double_freq_hz/1.1))*2]);
title(sprintf('Mean Difference FFT: %1.0f Trials', num_trials));
grid on;
yline(0, '--');
xline(double_freq_hz, '--');
xlabel('Frequency (Hz)');
ylabel('Amplitude (\muV)');
hold off;
savefig(f1, fullfile(figures_folder, [fig_prefix '_mean_diff_fft.fig']));
print(f1, fullfile(figures_folder, [fig_prefix '_mean_diff_fft.png']), '-dpng', '-r150');
close(f1);

% Mean STIM ON FFT
f2 = figure('Visible', 'off');
mean_fft = mean(stim_ON_fft,1);
std_fft = std(stim_ON_fft,0,1);

fill([freq_vec fliplr(freq_vec)], [mean_fft+std_fft fliplr(mean_fft-std_fft)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold on;
plot(freq_vec, mean_fft, 'Color', tableau_10('blue'), 'LineWidth', 1.5);
xlim([(double_freq_hz-(double_freq_hz/1.1))*2, (double_freq_hz+(double_freq_hz/1.1))*2]);
title(sprintf('Mean STIM ON FFT: %1.0f Trials', num_trials));
grid on;
yline(0, '--');
xline(double_freq_hz, '--');
xlabel('Frequency (Hz)');
ylabel('Amplitude (\muV)');
hold off;
savefig(f2, fullfile(figures_folder, [fig_prefix '_mean_stim_on_fft.fig']));
print(f2, fullfile(figures_folder, [fig_prefix '_mean_stim_on_fft.png']), '-dpng', '-r150');
close(f2);

% Noise floor distribution
f3 = figure('Visible', 'off');
noise_floor = ex.model.noise_floor{iamp};
noise_floor = mean(noise_floor,1);
histogram(noise_floor, 'FaceColor', tableau_10('blue'));
xlim([min(noise_floor), max(noise_floor)]);
title('Noise Floor Distribution');
xlabel('Amplitude (\muV)')
ylabel('Frequency');
savefig(f3, fullfile(figures_folder, [fig_prefix '_noise_floor.fig']));
print(f3, fullfile(figures_folder, [fig_prefix '_noise_floor.png']), '-dpng', '-r150');
close(f3);

% Difference FFT Bootstrapped distribution
f4 = figure('Visible', 'off');
doub_freq_diff_vec = ex.model.doub_freq_diff_vec;
[bootstat, lower_CI, upper_CI] = calculate_bootstrap(ex, doub_freq_diff_vec);

% Plot bootstrapped distribution in new figure
histogram(bootstat, 'FaceColor', tableau_10('blue'));
hold on;
xline(0, '--');
xline(lower_CI, 'Color', tableau_10('red'), 'LineWidth', 1.5);
xline(upper_CI, 'Color', tableau_10('red'), 'LineWidth', 1.5);
xlim('auto');
cur_xlim = xlim;
xlim([-max(abs(cur_xlim)), max(abs(cur_xlim))]);
title('Bootstrap Distribution');
xlabel('Difference (\muV)');
ylabel('Frequency');
grid on;
hold off;
savefig(f4, fullfile(figures_folder, [fig_prefix '_bootstrap.fig']));
print(f4, fullfile(figures_folder, [fig_prefix '_bootstrap.png']), '-dpng', '-r150');
close(f4);
end