%% posthoc_simulate_data
clearvars

%% Setup ex structure
app.DropDown_test_mode.Value = 'Mixed stimuli';
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
ex.info.experiment.exp_type = 'Mixed stimuli';
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
if strcmp(app.DropDown_test_mode.Value,'Adaptive') || strcmp(app.DropDown_test_mode.Value,'Mixed stimuli')
    ex = setup_analysis(ex); % Analysis deta/data
end
if strcmp(app.DropDown_test_mode.Value,'Adaptive')
    ex = setup_model(ex);
end

% Get the amplitudes we are testing with
amp_vec = ex.info.mixed.test_amplitudes;

%% Generate Stimulus Template
ex = select_experiment_stim_params(ex);
ex = make_stimulus_template(ex);

% Generate 2f response waveform
fs = ex.info.recording.sampling_rate_hz;
stim_freq = ex.info.stimulus.frequency_hz*2;
full_amp_stim_ON_ms = ex.info.stimulus.full_amplitude_duration_ms;
ramp_stim_ON_ms = ex.info.stimulus.ramp_duration_ms;
doub_waveform = generate_tone_burst(fs, stim_freq, full_amp_stim_ON_ms, ramp_stim_ON_ms);

% Generate simulated data
for ischedule = 1:length(ex.info.mixed.test_schedule)
    % Increment counters
    ex.counter.ischedule = ischedule;
    ex.counter.iblock = ex.counter.iblock + 1;
    iblock = ex.counter.iblock;
    ex.counter.grand_iblock = ex.counter.grand_iblock + 1;

    % Generate simulated data here
    trials_per_block = ex.info.trials.trials_per_block;
    trim_stim_pre_dur_ms = ex.info.stimulus.trim_stim_pre_dur_ms;

    % Get current stimuli parameters
    cur_parameters = ex.info.mixed.test_schedule(ex.counter.ischedule,:); % [stim_name, stim_amp, trials_needed, uniq_idx]
    cur_stim_name = ex.info.mixed.stim_name{cur_parameters(1)};
    current_amplitude = cur_parameters(2);

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
    ex.block_level_info(iblock).phase_vec = 2*(randperm(trials_per_block) <= trials_per_block/2)' - 1; % Make a fake phase_vec for posthoc analysis to work

    % Save metadata to block structure
    ex.block_level_info(iblock).stim_type = cur_stim_name;
    ex.block_level_info(iblock).stim_amp = current_amplitude;
    ex.block_level_info(iblock).unique_id = cur_parameters(4);

    % Simulate collection attempts
    ex.block_level_info(iblock).collection_attempts = 0;
    ex.block_level_info(iblock).kept_trials_idx = 1:ex.info.trials.trials_per_block;

    % Transform stimulus to simulate AEP by scaling 
    scale_factor = (current_amplitude-min(amp_vec)) / (max(amp_vec) - min(amp_vec));
    scaled_stimulus =  stimulus*scale_factor;

    %% Generate pink noise on per trial basis
    % Need to generate on per trial basis so it averages down
    % Preallocate
    my_noise = NaN(ex.info.trials.trials_per_block, size(stimulus,2));
    for itrial = 1:ex.info.trials.trials_per_block
        my_noise(itrial,:) = pinknoise(size(stimulus,2))';
    end

    %% Add scaled noise to finalize simulated AEP
    % Each electrode gets same noise floor but just scaled
    for ichan = 1:ex.info.channels.n_channels
        % Setup scale factor by channel
        if ichan == 1
            scale_factor = 1;
        elseif ichan == 2
            scale_factor = 2;
        elseif ichan == 3
            scale_factor = 1;
        elseif ichan == 4
            scale_factor = 4;
        end

        % Add scaled noise to simuluate electrode placement
        scaled_noise = my_noise*scale_factor;
        simulated_data = scaled_stimulus + scaled_noise;

        % Add simulated AEP to ex structure
        ex.raw_signals(iblock).electrodes_microV(:,:,ichan) = simulated_data;
    end
end

%% Save to posthoc script compatible grand_ex_save
% Remove fields
ex = rmfield(ex,'block');
ex = rmfield(ex.raw,'hydrophone_mV');
ex = rmfield(ex.raw,'loopback');
ex = rmfield(ex.raw,'time_stamp');

% Save to grand_ex_save structure
grand_ex_save{1,1}= ex;
save('simulated_data','grand_ex_save','-v7.3');
