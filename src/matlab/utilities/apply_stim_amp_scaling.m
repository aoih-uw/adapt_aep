function stimulus = apply_stim_amp_scaling(current_amplitude, correction_factor, stimulus)
% Apply amplitude scaling
% Level is relative to 1 which should output 170 dB
% System is set to output 130 dB at 0.01 (?) is this true?
%# Does the 0.01 we applied as headroom in the calibration code need to be
% applied here as well?
%# check with andrew if this is correct and walk me through the logic
% 0.01 scaling provides 40 dB headroom as used in calibration code
base_level = 10^((current_amplitude-170)/20);
corrected_level = base_level.*correction_factor;
stimulus = stimulus.*corrected_level;