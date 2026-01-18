function ex = make_tone_burst_template(ex)
% Make a ramped tone burst for selected frequency

% Extract data from ex
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.stimulus.frequency_hz;
full_amp_dur_ms = ex.info.stimulus.full_amplitude_duration_ms;
ramp_dur_ms = ex.info.stimulus.ramp_duration_ms;

% Nyquist check
if stim_freq >= fs/2
    error('make_tone_burst:NyquistViolation', ...
        'Stimulus frequency must be below Nyquist limit (fs/2 = %.1f Hz)', fs/2)
end

tone_burst = generate_tone_burst(fs, stim_freq, full_amp_dur_ms, ramp_dur_ms);

ex.info.stimulus.total_stimulus_duration_ms = (length(tone_burst)/fs)*ms_to_s;
ex.info.stimulus.waveform = tone_burst;