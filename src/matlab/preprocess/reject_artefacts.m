function ex = reject_artefacts(ex,app)
% Reject artefacts and display rate of rejection
% No distinction between different channels for analysis. They will all get
% pooled together
% Ensure = number of polarity after rejection
% Base stats on all available data
% Input: ex.raw(iblock).electrodes(n_trials, n_samples, n_channels)

% Define variables
iblock = ex.counter.iblock;
iamp = ex.counter.iamp;
rejection_threshold_microV = ex.info.signal_quality.rejection_threshold_microV;
reject_threshold_sd = ex.info.signal_quality.rejection_threshold_sd;
N_channels = ex.info.channels.n_channels;
analysis_channel = ex.info.channels.analysis_channel;
trials_per_block = ex.info.adaptive.trials_per_block; %# In test make sure trials_per_block*iblock calculations meet expectation on total length of trials below
N_trials_presented = ex.trial_count(iamp);
current_amplitude = ex.info.stimulus.amplitude_spl;
mad_to_std = ex.info.analysis.mad_to_std;

%% Get all available data
% Account for different sizes
max_samples = max(arrayfun(@(x) size(x.electrodes_microV, 2), ex.raw));
all_trials = NaN(trials_per_block*iblock, max_samples, N_channels);
all_phases = zeros(trials_per_block*iblock,N_channels);
all_jitter = zeros(trials_per_block*iblock,N_channels);
row_idx = 1;

for ii = 1:iblock
    cur_block = ex.raw(ii).electrodes_microV;
    cur_phase = ex.block(ii).phase_vec;
    cur_jitter = ex.block(ii).jitter;
    n_samples = size(cur_block, 2);
    
    for ichan = 1:N_channels
        temp = cur_block(:,:,ichan);
        all_trials(row_idx:row_idx+trials_per_block-1, 1:n_samples, ichan) = temp;
        all_phases(row_idx:row_idx+trials_per_block-1, ichan) = cur_phase;
        all_jitter(row_idx:row_idx+trials_per_block-1, ichan) = cur_jitter;
    end
    row_idx = row_idx + trials_per_block;
end

%% Identify artefactual trials across ALL CHANNELS
rejected_trials = [];
for ichan = 1:N_channels
    cur_chan_data_raw = squeeze(all_trials(:, :, ichan));
    cur_chan_data = sqrt(mean(cur_chan_data_raw.^2, 2, 'omitnan'));
    cur_median = median(cur_chan_data);
    cur_mad = median(abs(cur_median-cur_chan_data))*mad_to_std;
    rej_thresh = cur_median + cur_mad*reject_threshold_sd;
    rejected_trials = [rejected_trials find(cur_chan_data >= rej_thresh)'];
end
all_chan_rejected_trials = unique(rejected_trials);

% Save # of rejected trials to allow more trials to be collected
if strcmp(ex.info.experiment.exp_type,'Static trial count') || strcmp(ex.info.experiment.exp_type,'Adaptive')
    n_trials_collected = size(squeeze(all_trials(:,:,1)),1);
    if isempty(all_chan_rejected_trials)
        n_trials_rejected = 0;
    else
    n_trials_rejected = length(all_chan_rejected_trials);
    end
    n_valid_trials = n_trials_collected - n_trials_rejected;
    ex.valid_trials(iamp) = n_valid_trials;
    ex.rejected_trials{iamp} = all_chan_rejected_trials;
    reject_rate = n_trials_rejected/n_trials_collected;
    %% Report rejection rate
    if reject_rate > 0.5
        uialert(app.UIFigure, 'More than half of the trials have been rejected.', 'Warning', 'Icon', 'warning');
    end
    app.Label_rejection_rate.Text = sprintf('%d', n_valid_trials);
end

%% ADAPTIVE: Select only the analysis channel and reject trials based on this channel only
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    all_trials_chan = permute(all_trials, [1 3 2]); % Now: [trials × channels × timepoints]
    all_trials_chan = squeeze(all_trials_chan(:,analysis_channel,:));
    all_phases_chan = all_phases(:,analysis_channel);
    all_jitter_chan = all_jitter(:,analysis_channel);

    [kept_trials_idx, kept_trials_phases, rel_reject_threshold] = ...
        reject_and_balance_trials(all_trials_chan, all_phases_chan, ...
        rejection_threshold_microV, reject_threshold_sd);

    %% Save kept trials
    kept_trials = all_trials_chan(kept_trials_idx,:);
    kept_jitter = all_jitter_chan(kept_trials_idx);
    reject_rate = ((N_trials_presented)-size(kept_trials,1))/(N_trials_presented);
    fprintf('\nArtifact rejection rate: %.1f%%\n', reject_rate * 100);

%% Save to ex structure
ex.preprocess(iblock).rel_reject_threshold = rel_reject_threshold; % (1 x # iterations of preprocessing) saved in structure for every iamp
ex.preprocess(iblock).reject_rate = reject_rate;  % (1 x # iterations of preprocessing) saved in structure for every iamp
ex.kept.trials = kept_trials; % Don't need to save every iteration's data, so just save to first 
ex.kept.phases = kept_trials_phases;
ex.kept.jitter = kept_jitter;
end
