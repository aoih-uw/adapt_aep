function ex = create_new_stimuli_block(ex,app)
%% Handles assignment of variables to make_scaled_jittered_stim_block depending on test type (single stimulus vs. mixed)
% Assign variables
iblock = ex.counter.iblock;
waveform = ex.info.stimulus.waveform;
trials_per_block = ex.info.trials.trials_per_block;
trim_stim_pre_dur_ms = ex.info.stimulus.trim_stim_pre_dur_ms;

% Check if there are enough slots in ex.raw
if iblock > ex.info.trials.max_block
    idx = ex.info.trials.max_block + (1:10); % Add 10 more slots
    [ex.block(idx)] = deal(ex.template.block);
    [ex.raw(idx)] = deal(ex.template.raw);
    ex.info.trials.max_block = idx(end);
end

%% Select which stimuli type we will use
if strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
    % Get current test_schedule batch
    cur_parameters = ex.info.mixed.test_schedule(ex.counter.ischedule,:); % [stim_name, stim_amp, trials_needed, uniq_idx]
    cur_stim_name = ex.info.mixed.stim_name{cur_parameters(1)};
    current_amplitude = cur_parameters(2);
    if strcmp(cur_stim_name, 'trim')
        is_ONOFF = 0;
    elseif strcmp(cur_stim_name, 'ONOFF')
        is_ONOFF = 1;
    else
        keyboard
        error('Unrecognized stimulus type!')
    end

    ex.block(iblock).stim_type = cur_stim_name;
    ex.block(iblock).stim_amp = current_amplitude;
    ex.block(iblock).unique_id = cur_parameters(4);
    app.Label_current_amp.Text = string(current_amplitude);
elseif strcmp(app.DropDown_test_mode.Value, 'Adaptive')
    is_ONOFF = 1;
    current_amplitude = ex.info.stimulus.amplitude_spl;

elseif  strcmp(app.DropDown_test_mode.Value, 'Static trial count') ||  strcmp(app.DropDown_test_mode.Value, 'Timed')
    is_ONOFF = 0;
    current_amplitude = ex.info.stimulus.amplitude_spl;
else
    keyboard
    error('Unrecognized test mode!')
end

% Apply scaling, jittering to stimulus block
[ex, selected_cycle_samples, stimulus, phase_vec] = ...
    make_scaled_jittered_stim_block(ex, waveform, current_amplitude, trials_per_block, trim_stim_pre_dur_ms, is_ONOFF);

% Save to ex
ex.block(iblock).jitter = selected_cycle_samples;
ex.block(iblock).stimulus_block = stimulus;
ex.block(iblock).phase_vec = phase_vec;

% Check for NaNs
cellfun(@(v,t) check_for_nans(v,t), ...
    {ex.counter.iblock, ex.block(iblock).jitter, ...
    ex.block(iblock).stimulus_block, ex.block(iblock).phase_vec}, ...
    {'variable','variable','signal','variable'}, ...
     'UniformOutput',false);