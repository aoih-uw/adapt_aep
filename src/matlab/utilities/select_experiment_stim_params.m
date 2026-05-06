function ex = select_experiment_stim_params(ex)
% Determine full amplitude duration
stim_freq = ex.info.stimulus.frequency_hz;
stimulus_period = 1/stim_freq;
num_cycles = ex.info.stimulus.full_amplitude_cycle_num;% Minimum full amplitude duration ms is 20ms following Mooney et al. 2010
ex.info.stimulus.full_amplitude_duration_ms = max(20,stimulus_period*num_cycles*1e3);

ramp_dur_min = ex.info.stimulus.ramp_duration_min_ms;
ramp_dur_max = ex.info.stimulus.ramp_duration_max_ms;

% Determine ramp duration
if stim_freq >= 400
    ex.info.stimulus.ramp_duration_ms = ramp_dur_min;
else
    max_freq = 399;
    min_freq = ex.info.stimulus.min_frequency_limit;
    freq_weight = 1 - (stim_freq-min_freq) ./ (max_freq - min_freq);
    ex.info.stimulus.ramp_freq_weight = freq_weight;
    ex.info.stimulus.ramp_duration_ms = ceil(ramp_dur_min + (ramp_dur_max-ramp_dur_min)*freq_weight);
end


