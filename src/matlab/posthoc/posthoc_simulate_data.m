%% posthoc_simulate_data
clearvars

%% Setup ex structure
app.DropDown_test_mode.Value = 'Mixed freqs';
ex = setup_ex(app); % Create ex
ex.test = 1;
ex = setup_info(ex,app); % Setup info metadata

% Add GUI details manually
ex.info.animal.subject_ID = 1;
ex.info.animal.sex = 'F';
ex.info.stimulus.frequency_hz = 100;
ex.info.stimulus.type = 'Tone burst';
ex.info.experiment.response_feature = 'Double frequency';
ex.info.trials.max_trials = length(ex.info.mixed.test_schedule)*ex.info.trials.trials_per_block;
ex.info.experiment.timer_dur_min = NaN;
ex.info.experiment.exp_type = 'Mixed freqs';
ex.info.experiment.test_tag = 'test';
ex.info.animal.filename_root = sprintf('%s_%d_%gHz', ...
    'simulated_data', ...
    ex.info.animal.subject_ID, ...
    ex.info.stimulus.frequency_hz);
ex.info.recording.latency_samples = 2118;

% setup_block will set ex.info.trials.max_block;
ex.info.mixed.N_trials_per_file = ex.info.trials.max_trials;

% Set up sets of ex
ex = setup_block(ex); % Per amplitude meta/data

% Get the amplitudes we are testing with
amp_vec = ex.info.mixed.test_amplitudes;
amp_vec = sort(amp_vec);

% Create fake signal set
set_threshold = 110;
ending_slope_range = 5;
sig_vals = amp_vec >= set_threshold;
n_non_zeros = size(find(sig_vals),2);
n_zeros = length(sig_vals)-n_non_zeros;
n_soft_ramp = round(n_non_zeros/3); % 1/3 of non_zero values will be a soft ramp

% Slope is 1
for i = 1:n_soft_ramp 
    soft_ramp(i) = 0 + i;
end

% Slope is 5
for i =  1:length(sig_vals)-n_soft_ramp-n_zeros-ending_slope_range
    hard_ramp(i) = soft_ramp(end) + 5*i;
end

% Slope is 10
for i = 1:ending_slope_range
    harder_ramp(i) = hard_ramp(end) + 10*i;
end

scale_factor = [zeros(1,n_zeros) soft_ramp hard_ramp harder_ramp];

% Assign misc vars
trials_per_block = ex.info.trials.trials_per_block;
trim_stim_pre_dur_ms = ex.info.stimulus.trim_stim_pre_dur_ms;

%% Generate 2f response waveform template
% Select "stimulus" parameters
ex = select_experiment_stim_params(ex);

% Assign variables for tone burst generation
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.stimulus.frequency_hz*2;
full_amp_stim_ON_ms = ex.info.stimulus.full_amplitude_duration_ms;
ramp_stim_ON_ms = ex.info.stimulus.ramp_duration_ms;
doub_waveform = generate_tone_burst(fs, stim_freq, full_amp_stim_ON_ms, ramp_stim_ON_ms);
ex.info.stimulus.waveform = doub_waveform;

%% Generate simulated data
for ischedule = 1:length(ex.info.mixed.test_schedule)
    % Increment counters
    ex.counter.ischedule = ischedule;
    ex.counter.iblock = ex.counter.iblock + 1;
    iblock = ex.counter.iblock;
    ex.counter.grand_iblock = ex.counter.grand_iblock + 1;

    % Get current stimuli parameters
    cur_parameters = ex.info.mixed.test_schedule(ex.counter.ischedule,:); % [stim_name, stim_amp, trials_needed, uniq_idx]
    cur_stim_name = ex.info.mixed.stim_name{cur_parameters(1)};
    current_amplitude = cur_parameters(2);
    cur_amp_idx = find(current_amplitude == amp_vec);

    % Determine stim type
    if strcmp(cur_stim_name, 'trim')
        is_ONOFF = 0;
    elseif strcmp(cur_stim_name, 'ONOFF')
        is_ONOFF = 1;
    else
        keyboard
        error('Unrecognized stimulus type!')
    end

    % Make scaled, jittered, NON-antiphasic, ON/OFF or trimmed stimuli
    % We want to use non-antiphasic stimuli since we want to see the peak
    % at 2f frequency in the simulated data
    [ex, selected_cycle_samples, stimulus, phase_vec] = ...
        make_scaled_jittered_stim_block(ex, doub_waveform, current_amplitude, ...
        trials_per_block, trim_stim_pre_dur_ms, is_ONOFF);

    % Shift latency offset from end of stimulus to the beginning
    stimulus = circshift(stimulus, ex.info.recording.latency_samples,2);

    % Save to block data
    ex.block_level_info(iblock).jitter = selected_cycle_samples;
    % Make a fake phase_vec for posthoc analysis to work
    ex.block_level_info(iblock).phase_vec = 2*(randperm(trials_per_block) <= trials_per_block/2)' - 1;

    % Save metadata to block structure
    ex.block_level_info(iblock).stim_type = cur_stim_name;
    ex.block_level_info(iblock).stim_amp = current_amplitude;
    ex.block_level_info(iblock).unique_id = cur_parameters(4);

    % Simulate collection attempts
    ex.block_level_info(iblock).collection_attempts = 0;
    ex.block_level_info(iblock).kept_trials_idx = 1:ex.info.trials.trials_per_block;

    % Identify the full scale RMS of the stimulus to use to match noise rms
    % later
    full_scale_rms = median(max(stimulus,[],2));

    %% Generate pink noise on per trial basis
    % Need to generate on per trial basis so it averages down
    % Preallocate
    my_noise = NaN(ex.info.trials.trials_per_block, size(stimulus,2));
    for itrial = 1:ex.info.trials.trials_per_block
        tmp_noise = pinknoise(size(stimulus,2))';
        % Set noise rms to full scale
        my_mult = full_scale_rms/rms(tmp_noise);
        my_noise(itrial,:) = tmp_noise*my_mult;
    end
    

    % Setup signal and noise scaling factors
    chan_scale = [1 0.5 1 0.25];
    noise_scale = ones(1,4);

    % Apply scaling and noise to simulated AEP
    for ichan = 1:ex.info.channels.n_channels
        ex.raw_signals(iblock).electrodes_microV(:,:,ichan) = ...
            stimulus*scale_factor(cur_amp_idx)*chan_scale(ichan) + my_noise*noise_scale(ichan);
    end

    % Progress counter
    fprintf('%d / %d\n', ischedule, length(ex.info.mixed.test_schedule));
end


%% Save to posthoc script compatible grand_ex_save
% Remove fields
ex = rmfield(ex,'block');
ex = rmfield(ex,'raw');

% Save to grand_ex_save structure
grand_ex_save{1,1}= ex;
% save('simulated_data','grand_ex_save','-v7.3');
