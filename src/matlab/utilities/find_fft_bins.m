function [target_freq_range, max_val] = ...
    find_fft_bins(target_freq, target_freq_range, input_signal, freq_vec, is_bio_sig)
%% Extracts magnitude values from selected FFT bins
% Input structure requirements
% input_signal = trials x samples
% freq_vec = 1 x samples
freq_vec = freq_vec(:)';

%% Select target frequency bin based on highest amplitude within range
% This wider range is necessary since the 2f response is not always precisely at 2f
lower_end = target_freq - target_freq_range;
upper_end = target_freq + target_freq_range;

if is_bio_sig
    % Only consider positive values in the case that the peak is down shifted
    [~, targ_idx] = min(abs(freq_vec-target_freq));
    max_val = max(input_signal(:, targ_idx), [], 2);

else
    bin_idxs = freq_vec >= lower_end & freq_vec <= upper_end;
    max_val = max(input_signal(:, bin_idxs), [], 2);
end
