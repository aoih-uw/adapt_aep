function ex = reject_artefacts_single(ex,app)
% Reject artefacts and display rate of rejection
% No distinction between different channels for analysis. They will all get
% pooled together
% Ensure = number of polarity after rejection
% Base stats on all available data
% Input: ex.raw(iblock).electrodes(n_trials, n_samples, n_channels)

% Define variables
iblock = ex.counter.iblock;
first_block = 1;
iamp = ex.counter.iamp;
channel_names = ex.info.electrodes.names; 
valid_electrodes = find(~ismember(channel_names, {'EKG','X','Y','Z','Hydrophone','Loopback'}));
valid_channels = 1:numel(valid_electrodes); % To index into ex.raw(iblock).electrodes_microV(:,:,valid_channels(ivalid))
analysis_channel = ex.info.electrodes.analysis_channel;
analysis_channel_idx = find(ismember(channel_names(valid_electrodes),analysis_channel));
trials_per_block = ex.info.trials.trials_per_block;
N_trials_presented = ex.trial_count(iamp);

%% Get all available data
% Preallocate and account for different sizes
max_samples = max(arrayfun(@(x) size(x.electrodes_microV, 2), ex.raw));
all_trials = NaN(trials_per_block*iblock, max_samples, length(valid_channels));
all_phases = zeros(trials_per_block*iblock,1);
all_jitter = zeros(trials_per_block*iblock,1);

% Collapse raw data across all available batches
[all_trials, all_phases,all_jitter] = ...
    collapse_raw_data(all_trials, all_phases, all_jitter, iblock, first_block, ...
    trials_per_block, valid_electrodes, ex);

%% Reject artefacts
[kept_trials_idx, n_valid_trials, ...
    across_trial_thresh]  = ...
    reject_artefacts_and_balance_trials(ex, app, all_trials, all_phases,valid_channels);
ex.valid_trials(iamp) = n_valid_trials;

% Add threshold to block structure
ex.block(iblock).kept_trials_idx = kept_trials_idx;
ex.block(iblock).across_trial_thresh = across_trial_thresh;

