function ex = make_health_check_signal(ex)
% Create sound
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.health.stim_frequency_hz;
full_amp_dur_ms = ex.info.stimulus.full_amplitude_duration_ms;
ramp_dur_ms = ex.info.stimulus.ramp_duration_ms;

tone_burst = generate_tone_burst(fs, stim_freq, full_amp_dur_ms, ramp_dur_ms);

% Scale sound
stim_amplitude = ex.health.stim_amp_spl;
correction_factor = ex.info.calibration.correction_factor_linear;
head_room = ex.info.calibration.head_room;

tone_burst_scaled = apply_stim_amp_scaling(stim_amplitude, correction_factor, tone_burst, head_room);
tone_burst_set_scaled = repmat(tone_burst_scaled, 5, 1);

ex.health.waveforms = tone_burst_set_scaled;
