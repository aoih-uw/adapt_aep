function ex = preprocess_signal(ex,app)
%% Reject artefacts
ex = reject_artefacts(ex,app);

%% Apply inverse weighting of electrode signals
kept_trials = ex.kept.trials;
kept_trials_channels = ex.kept.channels;

% Check if there are any NaNs
check_for_nans(kept_trials,'signal')
check_for_nans(kept_trials_channels,'variable')

[ex, kept_trials_weighted, channel_weights]  = apply_channel_weights(ex,kept_trials,kept_trials_channels);
ex.kept.weight_vec = channel_weights;
ex.kept.trials_weighted = kept_trials_weighted;

% Check if there are any NaNs
check_for_nans(channel_weights,'variable')
check_for_nans(kept_trials_weighted,'signal')

%% Filter signals
fs = ex.info.recording.sampling_rate_hz;
pass_band_hz = ex.info.signal_quality.pass_band_hz;
[ex, kept_trials_filtered] = highpass_filter_signals(ex,fs,pass_band_hz,kept_trials_weighted);
ex.kept.trials_filtered = kept_trials_filtered;

% Check if there are any NaNs
check_for_nans(kept_trials_filtered,'signal')