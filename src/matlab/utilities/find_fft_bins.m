function target_bin_mag_vec = ...
    find_fft_bins(target_freq, target_freq_range, input_signal, freq_vec)
%% Extracts magnitude values from selected FFT bins
% Input structure requirements
% input_signal = n_trials x n_samples
% freq_vec = 1 x n_freq_resolution

freq_vec = freq_vec(:)'; % Force to be row vector

%% Select target frequency bin based on highest amplitude within range
% This wider range is necessary since the 2f response is not always precisely at 2f
lower_end = target_freq - target_freq_range;
upper_end = target_freq + target_freq_range;

bin_idxs = freq_vec >= lower_end & freq_vec <= upper_end;
target_bin_mag_vec = max(input_signal(:, bin_idxs), [], 2);
end