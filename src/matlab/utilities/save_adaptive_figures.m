function save_adaptive_figures(ex, folder)
iamp = ex.counter.iamp;
if ex.test == 1
    freq_2f_hz  = ex.info.stimulus.frequency_hz;
else
    freq_2f_hz  = ex.info.stimulus.frequency_hz*2;
end
diffs_fft = ex.fft.diffs;
stim_ON_fft = ex.fft.stim_ON;
freq_vec = ex.fft.freq_vec;
num_trials = size(diffs_fft,1);
figures_folder = fullfile(folder, 'figures');
fig_prefix = sprintf('%s_%ddBSPL', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl);

% Mean Difference FFT
f1 = figure('Visible', 'on');
mean_fft = mean(diffs_fft,1);
std_fft = std(diffs_fft,0,1);
fill([freq_vec fliplr(freq_vec)], [mean_fft+std_fft fliplr(mean_fft-std_fft)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold on;
plot(freq_vec, mean_fft, 'Color', tableau_10('blue'), 'LineWidth', 3);
xlim([(freq_2f_hz-(freq_2f_hz/1.1))*2, (freq_2f_hz+(freq_2f_hz/1.1))*2]);
title(sprintf('Mean Difference FFT at %1.0f Hz', freq_2f_hz/2));
grid off;
yline(0, '--');
xline(freq_2f_hz, '--');
xlabel('Frequency (Hz)');
ylabel('Amplitude (\muV)');
hold off;
save_with_unique_name(f1, fullfile(figures_folder, 'mean_diff_fft'), [fig_prefix '_mean_diff_fft']);
close(f1);

% Mean STIM ON FFT
f2 = figure('Visible', 'on');
mean_fft = mean(stim_ON_fft,1);
std_fft = std(stim_ON_fft,0,1);
fill([freq_vec fliplr(freq_vec)], [mean_fft+std_fft fliplr(mean_fft-std_fft)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold on;
plot(freq_vec, mean_fft, 'Color', tableau_10('blue'), 'LineWidth', 3);
xlim([(freq_2f_hz-(freq_2f_hz/1.1))*2, (freq_2f_hz+(freq_2f_hz/1.1))*2]);
title(sprintf('STIM ON FFT at %1.0f Hz', freq_2f_hz/2));
grid off;
yline(0, '--');
xline(freq_2f_hz, '--');
xlabel('Frequency (Hz)');
ylabel('Amplitude (\muV)');
hold off;
save_with_unique_name(f2, fullfile(figures_folder, 'mean_stim_on_fft'), [fig_prefix '_mean_stim_on_fft']);
close(f2);
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