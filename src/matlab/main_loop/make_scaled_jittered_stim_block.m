function [ex, selected_cycle_samples, stimulus, phase_vec] = ...
    make_scaled_jittered_stim_block(ex, waveform, current_amplitude, trials_per_block, is_ONOFF)
%% Creates a block of amplitude scaled stimuli with pre/post, jitter, and latency periods included 
% Assign variables
fs = ex.info.recording.sampling_rate_hz;
latency_samples = ex.info.recording.latency_samples;
cur_freq = ex.info.stimulus.frequency_hz;

correction_factor = ex.info.calibration.correction_factor_linear;

% Generate random phase offsets within one 60 Hz cycle
period_60_hz = 1/60; % time it takes to complete 1 cycle of 60 Hz (s)
selected_cycle_samples = ceil(rand(trials_per_block, 1) * period_60_hz * fs);

% Create alternating phase vector
if mod(trials_per_block,2) == 0
    phase_vec = 2*(randperm(trials_per_block) <= trials_per_block/2)' - 1;
else
    error('make_stim_block:oddTrials', 'The number of trials is not evenly divded by 2!')
end

%% Define [PRE, DUR, POST] stimulus periods
if is_ONOFF
    stim_OFF = zeros(1, length(waveform)); % Same length as stim ON
else
    stim_OFF = zeros(1,round(fs*5/1e3)); % 5 ms
end
stim_ON = waveform;

% Set POST stimulus duration depending on stimulus frequency
if cur_freq < 100
    post_stim = zeros(1, round(fs*600/1e3)); %  600 ms
elseif cur_freq >= 100 && cur_freq < 200
    post_stim = zeros(1,round(fs*100/1e3)); % 100 ms
elseif cur_freq >= 200 && cur_freq <= 800
    post_stim = zeros(1,round(fs*40/1e3)); % 40 ms
elseif  cur_freq > 800
    post_stim = zeros(1,round(fs*20/1e3)); % 20 ms
end
latency = zeros(1,latency_samples);

% Calculate maximum trial length
max_jitter = max(selected_cycle_samples);
max_length = max_jitter + length(stim_OFF) + length(stim_ON) + length(post_stim) + length(latency);

% Create block of trials
stimulus = zeros(trials_per_block, max_length);
for itrial = 1:trials_per_block
    phase = phase_vec(itrial);
    jitter = zeros(1, selected_cycle_samples(itrial));
    temp_stimulus = [jitter stim_OFF stim_ON post_stim latency]*phase;

    % Apply amplitude scaling
    temp_stimulus_scaled = apply_stim_amp_scaling(current_amplitude, correction_factor, temp_stimulus);
    stimulus(itrial, 1:length(temp_stimulus_scaled)) = temp_stimulus_scaled;
end
