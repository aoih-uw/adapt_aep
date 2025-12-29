function ex = make_stim_block(ex)
iblock = ex.block(end).iteration_num+1; % for the upcoming block

% Load variables
fs = ex.info.recording.sampling_rate_hz;
trials_per_block = ex.info.adaptive.trials_per_block;
waveform = ex.info.stimulus.waveform;

latency_samples = ex.info.recording.latency_samples;
current_amplitude = ex.info.stimulus.amplitude_spl;
correction_factor = ex.info.stimulus.calibration.correction_factor_sf;

% Generate random phase offsets within one 60 Hz cycle
period_60_hz = 1/60; % time it takes to complete 1 cycle of 60 Hz (s)
selected_cycle_samples = ceil(rand(trials_per_block, 1) * period_60_hz * fs);

 % Create alternating phase vector
if mod(trials_per_block,2) == 0
    phase_vec = 2*(randperm(trials_per_block) <= trials_per_block/2)' - 1;
else
    error('The number of trials is not evenly divded by 2!')
end

% Define [PRE, DUR, POST] stimulus periods
pre_stim = zeros(1, length(waveform));
dur_stim = waveform;
post_stim = zeros(1, length(waveform));
latency = zeros(1,latency_samples);

% Calculate maximum trial length
max_jitter = max(selected_cycle_samples);
max_length = max_jitter + length(pre_stim) + length(dur_stim) + length(post_stim) + length(latency);
 
% Create block of trials
stimulus = zeros(trials_per_block, max_length);
for itrial = 1:trials_per_block
    phase = phase_vec(itrial);
    jitter = zeros(1, selected_cycle_samples(itrial));
    temp_stimulus = [jitter pre_stim dur_stim post_stim latency]*phase;

    % Apply amplitude scaling
    temp_stimulus_scaled = apply_stim_amp_scaling(current_amplitude, correction_factor, temp_stimulus);
    stimulus(itrial, 1:length(temp_stimulus_scaled)) = temp_stimulus_scaled;
    
end

% Save to ex
ex.block(iblock).jitter = selected_cycle_samples;
ex.block(iblock).stimulus_block = stimulus;