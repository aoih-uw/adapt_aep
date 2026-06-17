function [kept_trials_idx, kept_trials_phases, rel_reject_threshold] = ...
    reject_and_balance_trials(all_trials_chan, all_phases_chan, ...
    rejection_threshold_microV, reject_threshold_sd)

% Calculate RMS per trial
all_trials_chan_rms = sqrt(mean(all_trials_chan.^2, 2, 'omitnan'));

% Relative rejection threshold based on median + MAD
all_median = median(all_trials_chan_rms, 1, 'omitnan');
all_mad = median(abs(all_median - all_trials_chan_rms));
rel_reject_threshold = all_median + reject_threshold_sd * all_mad *1.4826; % 1.4826 = mad to std conversion

% Keep trials below threshold
kept_trials_idx = find(all_trials_chan_rms < rejection_threshold_microV*10); % Tr out only rejection absolute threshold
% kept_trials_idx = find(all_trials_chan_rms < rel_reject_threshold & all_trials_chan_rms < rejection_threshold_microV);
kept_trials_phases = all_phases_chan(kept_trials_idx);

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
kept_trials_phases = all_phases_chan(kept_trials_idx);