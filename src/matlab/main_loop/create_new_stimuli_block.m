function ex = create_new_stimuli_block(ex,app)
iblock = ex.counter.iblock + 1; % for the upcoming block
ex.counter.iblock = iblock;

waveform = ex.info.stimulus.waveform;
trials_per_block = ex.info.adaptive.trials_per_block;
current_amplitude = ex.info.stimulus.amplitude_spl;

if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
    is_adaptive = 1;
elseif  strcmp(app.DropDown_test_mode.Value, 'Static trial count') ||  strcmp(app.DropDown_test_mode.Value, 'Timed')
    is_adaptive = 0;
end

[ex, selected_cycle_samples, stimulus, phase_vec] = ...
    make_scaled_jittered_stim_block(ex, waveform, current_amplitude, trials_per_block, is_adaptive);

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