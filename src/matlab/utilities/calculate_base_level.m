function base_level = calculate_base_level(target_level)
%% Get linear base value using 170 dB as the max value
% Digital value 1 = 170 dB
base_level = 10^((target_level-170)/20);
end