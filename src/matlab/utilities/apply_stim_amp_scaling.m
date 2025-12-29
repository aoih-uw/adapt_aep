function stimulus = apply_stim_amp_scaling(current_amplitude, correction_factor, stimulus)
% Apply amplitude scaling
% Level is relative to 1 which should output 170 dB
% System is set to output 130 dB at 0.1
%# check with andrew if this is correct and walk me through the logic
base_level = 10^((current_amplitude-170)/20);
corrected_level = base_level.*correction_factor;
stimulus = stimulus.*corrected_level;