function noise_distribution = ...
    calculate_fft_noise_floor(target_freq, target_freq_range, input_signal, freq_vec, exclude_harmonics)
% input_signal: 1xsamples (magnitude values)
% freq_vec: 1 x samples

if exclude_harmonics
% Exclude peaks at target freq and its harmonics
loc_2f = mod(freq_vec, target_freq) <= target_freq_range | ...
    mod(freq_vec, target_freq) >= (target_freq - target_freq_range);
end
% Exclude peaks near multiples of 60 Hz
loc_60_multiples = mod(freq_vec, 60) <= target_freq_range | ...
    mod(freq_vec, 60) >= (60 - target_freq_range);

% Calculate the median value of all peaks except 2f and 60 Hz multiples
if exclude_harmonics
    noise_distribution = input_signal(~loc_2f & ~loc_60_multiples);
else
    noise_distribution = input_signal(~loc_60_multiples);
end

if any(isnan(noise_distribution)) || length(noise_distribution) < 10
    keyboard
end
