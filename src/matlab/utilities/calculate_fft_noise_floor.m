function noise_distribution = ...
    calculate_fft_noise_floor(target_freq, target_freq_range, input_signal, freq_vec, exclude_harmonics)
%% Extracts magnitude values in fft bins associated with the noise floor (i.e., non target frequency bins)
if exclude_harmonics
    loc_2f = mod(freq_vec, target_freq) <= target_freq_range | ...
             mod(freq_vec, target_freq) >= (target_freq - target_freq_range);
else
    [~, loc_2f_bin] = min(abs(freq_vec - target_freq));  %#%# Change so it uses find_fft_bins_code
    loc_2f = false(size(freq_vec));
    loc_2f(loc_2f_bin) = true;
end

loc_60_multiples = mod(freq_vec, 60) <= target_freq_range | ...
                   mod(freq_vec, 60) >= (60 - target_freq_range);

noise_distribution = input_signal(~loc_2f & ~loc_60_multiples);

if any(isnan(noise_distribution)) || length(noise_distribution) < 10
    keyboard
    error('noise distribution vector has less than 10 values in it')
end