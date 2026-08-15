function ex = plan_stimulus_template(ex)
%% Assign stimulus parameter values to ex.info.stimulus on a per frequency basis
% Get stimulus parameters
fs = ex.info.recording.sampling_rate_hz;
for ifreq = 1:length(ex.info.stimulus)
    stim_freq = ex.info.stimulus(ifreq).frequency_hz;
    period_s = 1/stim_freq;
    period_samps = period_s*fs;
    ramp_cycles = ex.info.stimulus(ifreq).ramp_duration_cycles;
    desired_freq_res = ex.info.stimulus(ifreq).desired_freq_res;

    % Select stimulus parameters
    [full_amp_duration_ms, ramp_duration_ms]= select_experiment_stim_params(fs, stim_freq, period_s, period_samps, ramp_cycles, desired_freq_res);
    ex.info.stimulus(ifreq).full_amplitude_duration_ms = full_amp_duration_ms;
    ex.info.stimulus(ifreq).ramp_duration_ms = ramp_duration_ms;

    % Make stimulus template
    [tone_burst, total_sig_duration] = make_stimulus_template(fs, stim_freq,full_amp_duration_ms,ramp_duration_ms);
    ex.info.stimulus(ifreq).total_stimulus_duration_ms = total_sig_duration;
    ex.info.stimulus(ifreq).waveform = tone_burst;
end