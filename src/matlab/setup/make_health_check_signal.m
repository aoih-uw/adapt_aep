function ex = make_health_check_signal(ex)
ex.counter.ihealth = 0;
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.health.stimulus_frequency_hz;
stimulus_period = 1/stim_freq;
num_cycles = ex.info.stimulus.full_amplitude_cycle_num; 
full_amp_stim_ON_ms = stimulus_period*num_cycles*1e3;
ramp_stim_ON_ms = ex.info.health.ramp_duration_ms;
stim_amplitude = ex.info.health.stimulus_amplitude_spl;
trials_per_block = ex.info.adaptive.trials_per_block;

ex.info.health.make_health_sig = 1;

% Generate tone burst
tone_burst = generate_tone_burst(fs, stim_freq, full_amp_stim_ON_ms, ramp_stim_ON_ms);
ex.info.health.waveform = tone_burst;

%% Calibrate health signal
calibration_app = calibrate_stimulus();

% Initialize it with ex
calibration_app.initializeWithEx(ex);

t = timer('StartDelay', 0.1, 'TimerFcn', @(varargin) calibration_app.runCalibrate());            start(t);
uiwait(calibration_app.UIFigure);  % now listening before button fires
delete(t);

% Get the updated ex back
ex = calibration_app.ex;

% Clean up
delete(calibration_app)

[ex, ~, stimulus_block, phase_vec] = ...
        make_scaled_jittered_stim_block(ex, tone_burst, stim_amplitude, trials_per_block);

ex.info.health.phase_vec = phase_vec;
ex.info.health.stimulus_block = stimulus_block;

ex.info.health.make_health_sig = 0;
