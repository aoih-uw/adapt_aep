function [stim_ON , stim_OFF] = extract_stim_ON_OFF(latency_samples, period_length_samples, jitter_vec, signal)
% Signal = time-domain (trials x samples)
% Latency_samples = self explanatory
% jitter_vec = number of jitter samples used on trial basis (trial x 1)

stim_OFF_start = latency_samples + jitter_vec + 1; % Each trial has different jitter, and thus will have different starting points

stim_OFF = zeros(size(signal,1), period_length_samples); % (N_trials x time samples)
stim_ON = zeros(size(signal,1), period_length_samples);

for itrial = 1:size(signal,1) % Extract periods by trial
    cur_stim_OFF_start = stim_OFF_start(itrial);
    stim_OFF(itrial,:) = signal(itrial,cur_stim_OFF_start:cur_stim_OFF_start+period_length_samples-1);

    stim_ON_start = cur_stim_OFF_start+period_length_samples;
    stim_ON(itrial,:) = signal(itrial,stim_ON_start:stim_ON_start+period_length_samples-1);
end