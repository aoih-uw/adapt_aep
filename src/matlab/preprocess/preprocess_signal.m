function ex = preprocess_signal(ex,app)
%% Reject artefacts
ex = reject_artefacts(ex,app);

%% Apply inverse weighting of electrode signals
kept_trials = ex.kept.trials;
kept_trials_channels = ex.kept.channels;

% Check if there are any NaNs
NaN_trials = all(isnan(kept_trials), 2); % Check if there are full rows of NaNs
NaN_channels = isnan(kept_trials_channels);
if any(NaN_trials) || any(NaN_channels)
    keyboard % go into debug mode
end

[ex, kept_trials_weighted, channel_weights]  = apply_channel_weights(ex,kept_trials,kept_trials_channels);
ex.kept.weight_vec = channel_weights;
ex.kept.trials_weighted = kept_trials_weighted;

% Check if there are any NaNs
NaN_trials = all(isnan(kept_trials_weighted), 2); % Check if there are full rows of NaNs
NaN_weights = isnan(channel_weights);
if any(NaN_trials) || any(NaN_weights)
    keyboard % go into debug mode
end

%% Filter signals
fs = ex.info.recording.sampling_rate_hz;
pass_band_hz = ex.info.signal_quality.pass_band_hz;
[ex, kept_trials_filtered] = filter_signals(ex,fs,pass_band_hz,kept_trials_weighted);
ex.kept.trials_filtered = kept_trials_filtered;

% Check if there are any NaNs
NaN_trials = all(isnan(kept_trials_filtered), 2); % Check if there are full rows of NaNs
if any(NaN_trials)
    keyboard % go into debug mode
end