function base_level = calculate_base_level(target_level)
%% Calculates the linear digital amplitude value associated with our target 
%% dB SPL level relative to a max amplitude level (set to 170 dB)
% The denominator value represents what is associated with a digital value
% of 1
% Digital value 1 = 170 dB
base_level = 10^((target_level-170)/20);
end