function ex = create_new_stimuli_block(ex,app)

%% Assign variables
iblock = ex.counter.iblock;
waveform = ex.info.stimulus.waveform;
trials_per_block = ex.info.trials.trials_per_block;

%% Select which stimuli type we will use
if strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
    % Get current test_schedule batch
    cur_parameters = ex.info.mixed.test_schedule(ex.counter.ischedule,:); % [stim_name, stim_amp, trials_needed]
    cur_stim_name = ex.info.mixed.stim_name(cur_parameters(1));
    current_amplitude = cur_parameters(2);
    if strcmp(cur_stim_name, 'trim')
        is_ONOFF = 0;
    elseif strcmp(cur_stim_name, 'ONOFF')
        is_ONOFF = 1;
    end
elseif strcmp(app.DropDown_test_mode.Value, 'Adaptive')
    is_ONOFF = 1;
    current_amplitude = ex.info.stimulus.amplitude_spl;

elseif  strcmp(app.DropDown_test_mode.Value, 'Static trial count') ||  strcmp(app.DropDown_test_mode.Value, 'Timed')
    is_ONOFF = 0;
    current_amplitude = ex.info.stimulus.amplitude_spl;
end

% Apply scaling, jittering to stimulus block
[ex, selected_cycle_samples, stimulus, phase_vec] = ...
    make_scaled_jittered_stim_block(ex, waveform, current_amplitude, trials_per_block, is_ONOFF);

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