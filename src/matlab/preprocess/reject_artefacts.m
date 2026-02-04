function ex = reject_artefacts(ex)
% Reject artefacts and display rate of rejection
% No distinction between different channels for analysis. They will all get
% pooled together
% Ensure = number of polarity after rejection
% Base stats on all available data
% Input: ex.raw(iblock).electrodes(n_trials, n_samples, n_channels)

% Define variables
iblock = ex.counter.iblock;
reject_threshold_mV = ex.info.signal_quality.rejection_threshold_mV;
reject_threshold_sd = ex.info.signal_quality.rejection_threshold_sd;
N_channels = ex.info.channels.n_channels;
trials_per_block = ex.info.adaptive.trials_per_block; %# In test make sure trials_per_block*iblock calculations meet expectation on total length of trials below
total_trials_presented = iblock*trials_per_block;

%% Get all available data
sig_len = size(ex.raw(iblock).electrodes(1,:,1),2);
all_trials = zeros(trials_per_block*iblock,sig_len,N_channels);
all_phases = zeros(trials_per_block*iblock,N_channels);
all_jitter = zeros(trials_per_block*iblock,N_channels);
row_idx = 1;
for ii = 1:iblock
    cur_block = ex.raw(ii).electrodes;
    cur_phase = ex.block(ii).phase_vec;
    cur_jitter = ex.block(ii).jitter;
    for ichan = 1:N_channels
        temp = cur_block(:,:,ichan);
        all_trials(row_idx:row_idx+trials_per_block-1,:, ichan) = temp;
        all_phases(row_idx:row_idx+trials_per_block-1, ichan) = cur_phase;
        all_jitter(row_idx:row_idx+trials_per_block-1, ichan) = cur_jitter;
    end
        row_idx = row_idx+trials_per_block;
end

%% Collapse data across channels
all_trials_chan = zeros(trials_per_block*iblock*N_channels,sig_len);
all_phases_chan = zeros(trials_per_block*iblock*N_channels,1);
all_jitter_chan = zeros(trials_per_block*iblock*N_channels,1);

row_idx = 1;
all_channel_label = [];
for ichan = 1:N_channels
    all_channel_label = [all_channel_label ; ichan*ones(trials_per_block*iblock,1)];
    all_trials_chan(row_idx:row_idx+trials_per_block*iblock-1,:) = all_trials(:,:, ichan);
    all_phases_chan(row_idx:row_idx+trials_per_block*iblock-1,:) = all_phases(:,ichan);
    all_jitter_chan(row_idx:row_idx+trials_per_block*iblock-1,:) = all_jitter(:,ichan);
    row_idx = row_idx+trials_per_block*iblock;
end

%% Check for any crazy large values
if any(all_trials_chan(:) >= reject_threshold_mV)
    uiwait(warndlg('There are trials with suspiciously large mV values', 'Warning'));
end

%% Calculate RMS mean and std
all_trials_chan_rms = rms(all_trials_chan,2);
all_mean = mean(all_trials_chan_rms,1);
all_std = std(all_trials_chan_rms,1);

rel_reject_threshold = all_mean + reject_threshold_sd*all_std;

kept_trials_idx = find(all_trials_chan_rms < rel_reject_threshold);
kept_trials_phases = all_phases_chan(kept_trials_idx);

%% Check if even # of phases are kept
pos_phase_idx = find(kept_trials_phases == 1);
neg_phase_idx = find(kept_trials_phases == -1);

n_pos = length(pos_phase_idx);
n_neg = length(neg_phase_idx);
n_to_keep = min(n_pos,n_neg);

if n_pos ~= n_neg
    % Randomly select equal numbers from each phase
    if n_pos > n_to_keep
        pos_phase_idx = pos_phase_idx(randperm(n_pos, n_to_keep));
    end
    if n_neg > n_to_keep
        neg_phase_idx = neg_phase_idx(randperm(n_neg, n_to_keep));
    end
    
    % Combine and sort the balanced indices
    balanced_idx = sort([pos_phase_idx; neg_phase_idx]);
    
    % Update kept trials to only include balanced phases
    kept_trials_idx = kept_trials_idx(balanced_idx);
    kept_trials_phases = all_phases_chan(kept_trials_idx); %# keep for tests
end

%% Save kept trials
kept_trials = all_trials_chan(kept_trials_idx,:);
kept_trials_channels = all_channel_label(kept_trials_idx);
kept_jitter = all_jitter_chan(kept_trials_idx);
reject_rate = ((total_trials_presented*N_channels)-size(kept_trials,1))/(total_trials_presented*N_channels);
fprintf('Artifact rejection rate: %.3f', reject_rate)

%% Save to ex structure
ex.preprocess.rel_reject_threshold = [ex.preprocess.rel_reject_threshold rel_reject_threshold];
ex.preprocess.total_trials_presented =  [ex.preprocess.total_trials_presented total_trials_presented];
ex.preprocess.reject_rate =  [ex.preprocess.reject_rate reject_rate];
ex.preprocess.kept_trials = kept_trials;
ex.preprocess.kept_phases = kept_trials_phases;
ex.preprocess.kept_jitter = kept_jitter;
ex.preprocess.kept_channels = kept_trials_channels;
