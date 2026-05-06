function [target_freq_range, max_val] = ...
    find_fft_bins(target_freq, target_freq_range, input_signal, freq_vec)

% Input structure requirements
% input_signal = trials x samples
% freq_vec = 1 x samples

freq_vec = freq_vec(:)';

% Select double freq response values
lower_end = target_freq - target_freq_range;
upper_end = target_freq + target_freq_range;

bin_idxs = freq_vec >= lower_end & freq_vec <= upper_end;
found_idxs = find(bin_idxs);
bin_freq_vec = freq_vec(bin_idxs);
[~, bin_idx_2f] = min(abs(bin_freq_vec-target_freq));
n_tries = 0;

if isempty(bin_idx_2f)
    keyboard
end

max_val = input_signal(:,found_idxs(bin_idx_2f)); % Keep rows across trials


