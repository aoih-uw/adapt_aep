function [target_freq_range, mean_across_bins] = ...
    find_fft_bins(target_freq, target_freq_range, input_signal, freq_vec)

% Input structure requirements
% input_signal = trials x samples
% freq_vec = 1 x samples

freq_vec = freq_vec(:)';

% Select double freq response values
lower_end = target_freq - target_freq_range;
upper_end = target_freq + target_freq_range;

bin_idxs = freq_vec >= lower_end & freq_vec <= upper_end;
n_tries = 0;

while sum(bin_idxs) == 0 && n_tries < 15
    warning('Did not find bins within range. Going to increase range by 1 Hz')
    n_tries = n_tries + 1;
    target_freq_range = target_freq_range + 1;
    lower_end = target_freq - target_freq_range;
    upper_end = target_freq + target_freq_range;
    bin_idxs = freq_vec >= lower_end & freq_vec <= upper_end;
end

if n_tries >= 15
    error('No fft bins found')
else
    mean_across_bins = mean(input_signal(:,bin_idxs),2,'omitnan'); % Keep rows across trials
end

