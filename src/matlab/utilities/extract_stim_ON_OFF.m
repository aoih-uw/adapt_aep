function [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
    signal, isONOFF, fs, ...
    latency_samples, period_length_samples, ramp_duration_samples,...
    trim_stim_pre_dur_ms,...
    jitter_vec)
%% Extract stimulus OFF and ON periods in the time domain signal and remove on/off ramp portion from both periods
% Signal = time-domain (n_trials x n_samples)
% Latency_samples = self explanatory
% jitter_vec = number of jitter samples used on trial basis (trial x 1)

% Preallocate
stim_ON = NaN(size(signal,1), period_length_samples);

if isONOFF
    % Each trial has different jitter, and thus will have different starting points
    % Preallocate stim_OFF
    stim_OFF = NaN(size(signal,1), period_length_samples); % (N_trials x time samples)

    stim_OFF_start = latency_samples + jitter_vec + 1;

    for itrial = 1:size(signal,1) % Extract periods by trial
        cur_stim_OFF_start = stim_OFF_start(itrial);
        stim_OFF(itrial,:) = signal(itrial,cur_stim_OFF_start:cur_stim_OFF_start+period_length_samples-1);

        stim_ON_start = cur_stim_OFF_start+period_length_samples;
        stim_ON(itrial,:) = signal(itrial,stim_ON_start:stim_ON_start+period_length_samples-1);
    end
else
    % Preallocate stim_OFF
    stim_OFF = NaN(size(signal,1), (latency_samples+ round(trim_stim_pre_dur_ms/1e3*fs)-1));

    for itrial = 1:size(signal,1)
        stim_start = latency_samples + jitter_vec(itrial) + round(trim_stim_pre_dur_ms/1e3*fs); % stimulus just begins (i.e., start of onramp)
        stim_OFF(itrial,:) = signal(itrial,1:stim_start-1-jitter_vec(itrial)); % Jitter duration will be different for each trial so just remove it
        stim_ON(itrial,:) = signal(itrial,stim_start: stim_start+period_length_samples-1);
    end
end

%% Trim off ramps
stim_ON = stim_ON(:,ramp_duration_samples+1:end-ramp_duration_samples);

% Only trim stim_OFF when isONOFF
if isONOFF
    stim_OFF = stim_OFF(:,ramp_duration_samples+1:end-ramp_duration_samples);
end
