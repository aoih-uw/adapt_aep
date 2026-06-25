function ex = reject_artefacts_mixed(ex,app)

% Define variables
iblock = ex.counter.iblock;
N_channels = ex.info.channels.n_channels;
trials_per_block = ex.info.trials.trials_per_block; %# In test make sure trials_per_block*iblock calculations meet expectation on total length of trials below

% Get all iblocks that are relevant for the current stimulus type we are
% working with
first_block = iblock - ex.counter.N_not_enough_trials;

% Preallocate and account for different sizes
max_samples = max(arrayfun(@(x) size(x.electrodes_microV, 2), ex.raw(first_block:iblock)));
n_blocks = iblock - first_block + 1;
all_trials = NaN(trials_per_block * n_blocks, max_samples, N_channels);
all_phases = zeros(trials_per_block * n_blocks);
all_jitter = zeros(trials_per_block * n_blocks);

% Populate matrices
row_idx = 1;
for ii = first_block:iblock
    cur_block = ex.raw(ii).electrodes_microV;
    cur_phase = ex.block(ii).phase_vec;
    cur_jitter = ex.block(ii).jitter;
    n_samples = size(cur_block, 2);

    for ichan = 2:N_channels
        temp = cur_block(:,:,ichan);
        all_trials(row_idx:row_idx+trials_per_block-1, 1:n_samples, ichan) = temp;
    end
    all_phases(row_idx:row_idx+trials_per_block-1) = cur_phase;
    all_jitter(row_idx:row_idx+trials_per_block-1) = cur_jitter;
    row_idx = row_idx + trials_per_block;
end

% Reject trials here
[kept_trials_idx, n_valid_trials, ...
    across_trial_thresh, within_trial_thresh]  = ...
    reject_artefacts_and_balance_trials(ex, app, all_trials, all_phases);

ex.block(iblock).kept_trials_idx = kept_trials_idx;
ex.block(iblock).collection_attempts = ex.counter.N_not_enough_trials;
ex.block(iblock).across_trial_thresh = across_trial_thresh;
ex.block(iblock).within_trial_thresh = within_trial_thresh;

if n_valid_trials < trials_per_block
    ex.counter.N_not_enough_trials = ex.counter.N_not_enough_trials + 1;
else
    ex.counter.N_not_enough_trials = 0;
end