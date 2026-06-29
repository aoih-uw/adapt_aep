function stimulus = apply_stim_amp_scaling(current_amplitude, correction_factor, stimulus)
%% Applies scaling of input stimulus based on a linear correction factor that 
%% is based on a "base_level" that was used in the calibration process

% Input
% current_amplitude: The amplitude you want to correct to
% correction_factor: The linear correction factor that was calculated during the calibration process
% stimulus: The stimulus you want to scale

% Function vars
% base_level: The linear value relative to the max output level we defined (170 dB)
% corrected_level: The stimulus itself applied with the corrected digital linear factor

% Output
% stimulus: the scaled stimulus

base_level = calculate_base_level(current_amplitude);
corrected_level = base_level.*correction_factor;
stimulus = stimulus.*corrected_level;