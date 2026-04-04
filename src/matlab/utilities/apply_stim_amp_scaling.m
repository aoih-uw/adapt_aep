function stimulus = apply_stim_amp_scaling(current_amplitude, correction_factor, stimulus)

base_level = 10^((current_amplitude-170)/20);
corrected_level = base_level.*correction_factor;
stimulus = stimulus.*corrected_level;