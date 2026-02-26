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
reject_threshold_mV = ex.info.signal_quality.rejection_threshold_mV;
reject_threshold_sd = ex.info.signal_quality.rejection_threshold_sd;
N_channels = ex.info.channels.n_channels;
trials_per_block = ex.info.adaptive.trials_per_block; %# In test make sure trials_per_block*iblock calculations meet expectation on total length of trials below
N_trials_presented = ex.trial_count(iamp);
current_amplitude = ex.info.stimulus.amplitude_spl;

% Make channel labels
all_channel_label = [];
for ichan = 1:N_channels
    all_channel_label = [all_channel_label ; ones(trials_per_block*iblock,1)*ichan];
end

% For new iamp initialize new layer in ex.preprocess
if iamp > length(ex.preprocess)
    ex.preprocess(iamp).rel_reject_threshold = {};
    ex.preprocess(iamp).N_trials_presented = {};
    ex.preprocess(iamp).reject_rate = {};
end

%% Get all available data
% Account for different sizes
max_samples = max(arrayfun(@(x) size(x.electrodes, 2), ex.raw));
all_trials = NaN(trials_per_block*iblock, max_samples, N_channels);
all_phases = zeros(trials_per_block*iblock,N_channels);
all_jitter = zeros(trials_per_block*iblock,N_channels);
row_idx = 1;

for ii = 1:iblock
    cur_block = ex.raw(ii).electrodes;
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

%% Collapse data across channels
all_trials_chan = permute(all_trials, [1 3 2]); % Now: [trials × channels × timepoints]
all_trials_chan = reshape(all_trials_chan, [], size(all_trials,2)); % Now: [(trials*channels) × timepoints]
all_phases_chan = reshape(all_phases,[],1);
all_jitter_chan = reshape(all_jitter,[],1);

[kept_trials_idx, kept_trials_phases] = ...
    reject_and_balance_trials(all_trials_chan, all_phases_chan, ...
    reject_threshold_mV, reject_threshold_sd);

%% Save kept trials
kept_trials = all_trials_chan(kept_trials_idx,:);
kept_trials_channels = all_channel_label(kept_trials_idx); % Kept_trials_channels the labels for the channels
kept_jitter = all_jitter_chan(kept_trials_idx);
reject_rate = ((N_trials_presented*N_channels)-size(kept_trials,1))/(N_trials_presented*N_channels);
fprintf('\nArtifact rejection rate: %.3f\n', reject_rate)

% Update GUI
app.Label_rejection_rate.Text = sprintf('%.1f%%', reject_rate * 100);

%% Save to ex structure
ex.preprocess(iamp).rel_reject_threshold{end+1} = rel_reject_threshold; % (1 x # iterations of preprocessing) saved in structure for every iamp
ex.preprocess(iamp).N_trials_presented{end+1} =  N_trials_presented ; % (1 x # iterations of preprocessing) saved in structure for every iamp
ex.preprocess(iamp).reject_rate{end+1} = reject_rate;  % (1 x # iterations of preprocessing) saved in structure for every iamp
ex.kept.trials = kept_trials; % Don't need to save every iteration's data, so just save to first 
ex.kept.phases = kept_trials_phases;
ex.kept.jitter = kept_jitter;
ex.kept.channels = kept_trials_channels;
