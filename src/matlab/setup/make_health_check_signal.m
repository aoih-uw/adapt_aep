function ex = make_health_check_signal(ex)
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.health.stim_frequency_hz;
full_amp_dur_ms = ex.info.stimulus.full_amplitude_duration_ms;
ramp_dur_ms = ex.info.stimulus.ramp_duration_ms;
stim_amplitude = ex.info.health.stim_amp_spl;
trials_per_block = ex.info.adaptive.trials_per_block;

tone_burst = generate_tone_burst(fs, stim_freq, full_amp_dur_ms, ramp_dur_ms);
[ex, ~, stimulus_block, phase_vec] = ...
        make_stim_block(ex, tone_burst, stim_amplitude, trials_per_block);

ex.info.health.phase_vec = phase_vec;
ex.info.health.stimulus_block = stimulus_block;
