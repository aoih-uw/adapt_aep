function stimulus = apply_stim_amp_scaling(current_amplitude, correction_factor, stimulus)

base_level = calculate_base_level(current_amplitude);
corrected_level = base_level.*correction_factor;
stimulus = stimulus.*corrected_level;