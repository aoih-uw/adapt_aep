function my_snr = calculate_fft_snr(signal, freq_vec, target_freq, target_freq_range, exclude_harmonics)
%% Calculate SNR within the same fft vector
% Get signal fft bin value
[signal_fft_bin, ~] = find_fft_bins(target_freq, target_freq_range, signal, freq_vec);

% Get noise floor fft bin values
noise_distribution = ...
    calculate_fft_noise_floor(target_freq, target_freq_range, signal, freq_vec, exclude_harmonics);

% noise_median = median(noise_distribution);
noise_mean = mean(noise_distribution);

my_snr = 20*log10(signal_fft_bin/noise_mean);