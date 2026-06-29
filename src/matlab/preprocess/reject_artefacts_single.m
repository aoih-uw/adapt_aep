function ex = reject_artefacts_single(ex,app)
% Reject artefacts and display rate of rejection
% No distinction between different channels for analysis. They will all get
% pooled together
% Ensure = number of polarity after rejection
% Base stats on all available data
% Input: ex.raw(iblock).electrodes(n_trials, n_samples, n_channels)

% Define variables
iblock = ex.counter.iblock;
iamp = ex.counter.iamp;
channel_names = ex.info.channels.names;
valid_channels = find(~strcmp(channel_names, 'EKG'));
analysis_channel = ex.info.channels.analysis_channel;
trials_per_block = ex.info.trials.trials_per_block;
N_trials_presented = ex.trial_count(iamp);

%% Get all available data
% Preallocate and account for different sizes
max_samples = max(arrayfun(@(x) size(x.electrodes_microV, 2), ex.raw));
all_trials = NaN(trials_per_block*iblock, max_samples, length(valid_channels));
all_phases = zeros(trials_per_block*iblock,1);
all_jitter = zeros(trials_per_block*iblock,1);

% Populate matrices
row_idx = 1;
for ii = 1:iblock
    cur_block = ex.raw(ii).electrodes_microV;
    cur_phase = ex.block(ii).phase_vec;
    cur_jitter = ex.block(ii).jitter;
    n_samples = size(cur_block, 2);

    for ichan = 1:length(valid_channels)
        cur_chan = valid_channels(ichan);
        temp = cur_block(:,:,cur_chan);
        all_trials(row_idx:row_idx+trials_per_block-1, 1:n_samples, ichan) = temp;
    end
    all_phases(row_idx:row_idx+trials_per_block-1) = cur_phase;
    all_jitter(row_idx:row_idx+trials_per_block-1) = cur_jitter;
    row_idx = row_idx + trials_per_block;
end


%% Reject artefacts
[kept_trials_idx, n_valid_trials, ...
    across_trial_thresh, within_trial_thresh]  = ...
    reject_artefacts_and_balance_trials(ex, app, all_trials, all_phases,valid_channels);
ex.valid_trials(iamp) = n_valid_trials;

% Add threshold to block structure
ex.block(iblock).kept_trials_idx = kept_trials_idx;
ex.block(iblock).across_trial_thresh = across_trial_thresh;
ex.block(iblock).within_trial_thresh = within_trial_thresh;

%% ADAPTIVE: Select only the analysis channel keep those trials
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    kept_trials = all_trials(kept_trials_idx,:,analysis_channel); % Only keep the analysis channel
    kept_phases = all_phases(kept_trials_idx);
    kept_jitter = all_jitter(kept_trials_idx);
    reject_rate = ((N_trials_presented)-size(kept_trials,1))/(N_trials_presented);
    fprintf('\nArtifact rejection rate: %.1f%%\n', reject_rate * 100);

    %% Save to ex structure
    ex.kept.trials = kept_trials; % Don't need to save every iteration's data, so just save to first
    ex.kept.phases = kept_phases;
    ex.kept.jitter = kept_jitter;
end
