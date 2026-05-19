function [target_freq_range, max_val] = ...
    find_fft_bins(target_freq, target_freq_range, input_signal, freq_vec, is_bio_sig)

% Input structure requirements
% input_signal = trials x samples
% freq_vec = 1 x samples

freq_vec = freq_vec(:)';

% Select double freq response values
% This wider range is necessary since the 2f response is not always
% precisely at 2f
lower_end = target_freq - target_freq_range;
upper_end = target_freq + target_freq_range;

bin_idxs = freq_vec >= lower_end & freq_vec <= upper_end;

if is_bio_sig
    % Only consider positive values in the case that the peak is down shifted
    select_bins = find(bin_idxs);
    if isempty(select_bins)
        keyboard
    end
    pos_idx = mean(input_signal(:, select_bins), 1) > 0;
    if ~any(pos_idx) % Just take the mean across all values within range
        max_val = mean(input_signal(:, bin_idxs), 2);
    else
        max_val = mean(input_signal(:, select_bins(pos_idx)), 2);
    end
else
    max_val = max(input_signal(:, bin_idxs), [], 2);
end
