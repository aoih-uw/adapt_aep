function ex = stim_block_creation(ex)
iblock = ex.counter.iblock + 1; % for the upcoming block
ex.counter.iblock = iblock;

waveform = ex.info.stimulus.waveform;
trials_per_block = ex.info.adaptive.trials_per_block;
current_amplitude = ex.info.stimulus.amplitude_spl;

[ex, selected_cycle_samples, stimulus, phase_vec] = ...
    make_stim_block(ex, waveform, current_amplitude, trials_per_block);

% Save to ex
ex.block(iblock).jitter = selected_cycle_samples;
ex.block(iblock).stimulus_block = stimulus;
ex.block(iblock).phase_vec = phase_vec;