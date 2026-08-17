function ex = create_new_stimuli_block(ex,app)
%% Handles assignment of variables to make_scaled_jittered_stim_block depending on test type (single stimulus vs. mixed)
% Assign variables
iblock = ex.counter.iblock;
trials_per_block = ex.info.trials.trials_per_block;

% Check if there are enough slots in ex.raw
if iblock > ex.info.trials.max_block
    idx = ex.info.trials.max_block + (1:10); % Add 10 more slots
    [ex.block(idx)] = deal(ex.template.block);
    [ex.raw(idx)] = deal(ex.template.raw);
    ex.info.trials.max_block = idx(end);
end

% Assign stimulus parameters based on experiment type
switch ex.info.experiment.exp_type
    case 'Mixed freqs'
        % Get current test_schedule batch
        freq_idx = get_current_freq_idx(ex);
        stim_freq = ex.info.stimulus(freq_idx).frequency_hz;
        cur_parameters = ex.info.mixed.test_schedule(ex.counter.ischedule,:); % [stim_freq, stim_name, stim_amp, trials_needed, uniq_idx]
        stim_name = ex.info.mixed.stim_name{cur_parameters(2)};
        current_amplitude = cur_parameters(3);

        % Assign to block metadata
        ex.block(iblock).stim_freq = stim_freq;
        ex.block(iblock).stim_amp = current_amplitude;
        ex.block(iblock).unique_id = cur_parameters(5);

    case 'Adaptive'
        stim_name = 'ONOFF';
        freq_idx = 1;
        current_amplitude = ex.info.stimulus(freq_idx).amplitude_spl;
        stim_freq = ex.info.stimulus(freq_idx).frequency_hz;

    case {'Static trial count', 'Timed'}
        stim_name = 'Trim';
        freq_idx = 1;
        current_amplitude = ex.info.stimulus(freq_idx).amplitude_spl;
        stim_freq = ex.info.stimulus(freq_idx).frequency_hz;

    otherwise
        error('Unrecognized test mode: %s', app.DropDown_test_mode.Value);
end

% Assign stim type
is_ONOFF = strcmp(stim_name, 'ONOFF');
ex.block(iblock).stim_type = stim_name;

% Get Stimulus Template
waveform = ex.info.stimulus(freq_idx).waveform;
trim_stim_pre_dur_ms = ex.info.stimulus(freq_idx).trim_stim_pre_dur_ms;
correction_factor = ex.info.calibration(freq_idx).correction_factor_linear;

% Apply scaling, jittering to stimulus block
[ex, selected_cycle_samples, stimulus, phase_vec] = ...
    make_scaled_jittered_stim_block(ex, waveform, current_amplitude, trials_per_block, ...
    trim_stim_pre_dur_ms, is_ONOFF, stim_freq, correction_factor);

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