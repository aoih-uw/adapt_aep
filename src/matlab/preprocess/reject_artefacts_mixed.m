function ex = reject_artefacts_mixed(ex,app)
%% Reject artefacts in mixed stimulus mode
% Define variables
iblock = ex.counter.iblock;
channel_names = ex.info.channels.names;
valid_channels = find(~strcmp(channel_names, 'EKG'));
trials_per_block = ex.info.trials.trials_per_block;
ischedule = ex.counter.ischedule;

% Get all iblocks that are relevant for the current stimulus type we are working with
if ex.counter.N_not_enough_trials >= iblock
    keyboard
    error('N_not_enough_trials is larger than iblock, which should not happen')
else
    first_block = iblock - ex.counter.N_not_enough_trials;
end

% Preallocate and account for different sizes
max_samples = max(arrayfun(@(x) size(x.electrodes_microV, 2), ex.raw(first_block:iblock)));
n_blocks = iblock - first_block + 1;
all_trials = NaN(trials_per_block * n_blocks, max_samples, length(valid_channels)); % all_trials will only include valid channel layers
all_phases = zeros(trials_per_block * n_blocks,1);
all_jitter = zeros(trials_per_block * n_blocks,1);

% Collapse raw data across all available batches
[all_trials, all_phases, all_jitter] = ...
    collapse_raw_data(all_trials, all_phases, all_jitter, iblock, first_block, ...
    trials_per_block, valid_channels, ex);

% Reject trials here
[kept_trials_idx, n_valid_trials, ...
    across_trial_thresh]  = ...
    reject_artefacts_and_balance_trials(ex, app, all_trials, all_phases, valid_channels);

% Save values to ex.block field
ex.kept.trials = all_trials(kept_trials_idx,:,:); % Used in count_trials plotting
ex.kept.phases = all_phases(kept_trials_idx);
ex.kept.jitter = all_jitter(kept_trials_idx);

% Increment trial counter
cur_trial_type = ex.info.mixed.test_schedule(ischedule,4);
ex.info.mixed.trial_counter(cur_trial_type) = ...
    ex.info.mixed.trial_counter(cur_trial_type) + size(ex.kept.trials,1);

ex.block(iblock).kept_trials_idx = kept_trials_idx;
ex.block(iblock).collection_attempts = ex.counter.N_not_enough_trials;
ex.block(iblock).across_trial_thresh = across_trial_thresh;

if n_valid_trials < trials_per_block
    ex.counter.N_not_enough_trials = ex.counter.N_not_enough_trials + 1;
else
    ex.counter.N_not_enough_trials = 0;
end