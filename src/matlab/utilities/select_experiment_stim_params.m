function ex = select_experiment_stim_params(ex)
% Determine full amplitude duration
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.stimulus.frequency_hz;
stimulus_period = 1/stim_freq;

% Full amp duration
full_amp_cycles = ex.info.stimulus.full_amplitude_cycle_num; % Minimum full amplitude duration ms is 20ms following Mooney et al. 2010
cur_full_amp_dur_samps = round(stimulus_period*full_amp_cycles*fs);

ramp_cycles = ex.info.stimulus.ramp_duration_cycles;
ramp_ms =  stimulus_period*ramp_cycles*1e3;

% Ramp cycle duration
ex.info.stimulus.ramp_duration_ms = max(ramp_ms, 25);

% Full amp duration
desired_freq_res = 5; %fs/N = 5
min_req_samples = ceil(fs/desired_freq_res);
full_samp = max(cur_full_amp_dur_samps, min_req_samples);
ex.info.stimulus.full_amplitude_duration_ms = full_samp/fs*1e3;


