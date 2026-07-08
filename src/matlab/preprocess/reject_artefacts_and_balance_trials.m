function [kept_trials_idx, n_valid_trials, rel_rej_thresh_across ]  = ...
    reject_artefacts_and_balance_trials(ex, app, all_trials, all_phases,valid_channels)
%% Here you actually reject trials and balance the kept trials to include even numbers of both stimulus phases
% Assign variables
reject_threshold_sd = ex.info.signal_quality.rejection_threshold_sd;
mad_to_std = ex.info.signal_quality.mad_to_std;
clipping_threshold = 300; % microV

% Preallocate before the loop
rejected_trials = [];
rel_rej_thresh_across = NaN(1, length(valid_channels));
for ichan = 1:length(valid_channels)
    % Get data
    cur_chan_data_raw = squeeze(all_trials(:, :, ichan));

    % Reject by clipping
    rejected_trials = [rejected_trials find(any(abs(cur_chan_data_raw) >= clipping_threshold,2))'];

    % Reject by comparing RMS across trials
    cur_chan_data = sqrt(mean(cur_chan_data_raw.^2, 2, 'omitnan'));
    cur_median = median(cur_chan_data,'omitnan');
    cur_mad = median(abs(cur_median-cur_chan_data),'omitnan')*mad_to_std;
    rel_rej_thresh_across(ichan) = cur_median + cur_mad*reject_threshold_sd;
    rejected_trials = [rejected_trials find(cur_chan_data >= rel_rej_thresh_across(ichan))'];
end
all_chan_rejected_trials = unique(rejected_trials);

% Balance trials based on phase
% Keep trials below threshold
kept_trials_idx = setdiff(1:size(all_trials,1),all_chan_rejected_trials);
kept_trials_phases = all_phases(kept_trials_idx);

% Balance positive and negative phase trials
pos_phase_idx = find(kept_trials_phases == 1);
neg_phase_idx = find(kept_trials_phases == -1);
n_to_keep = min(length(pos_phase_idx), length(neg_phase_idx));

if length(pos_phase_idx) > n_to_keep
    pos_phase_idx = pos_phase_idx(randperm(length(pos_phase_idx), n_to_keep));
end
if length(neg_phase_idx) > n_to_keep
    neg_phase_idx = neg_phase_idx(randperm(length(neg_phase_idx), n_to_keep));
end

balanced_idx = sort([pos_phase_idx; neg_phase_idx]);
kept_trials_idx = kept_trials_idx(balanced_idx);

%% Report rejected trials
n_trials_collected = size(squeeze(all_trials(:,:,1)),1);
n_trials_rejected = n_trials_collected - length(kept_trials_idx);
n_valid_trials = length(kept_trials_idx);
reject_rate = n_trials_rejected/n_trials_collected;

%% Report rejection rate
if reject_rate > 0.5
    % Alert experimenter will do health check
    [y, Fs] = audioread('half_trials_reject.mp3');
    sound(y, Fs)
    fprintf('More than half of the trials have been rejected.')
end
app.Label_rejection_rate.Text = sprintf('%d', n_valid_trials);