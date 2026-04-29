function ex = preprocess_signal(ex,app)
fs = ex.info.recording.sampling_rate_hz;
pass_band_hz = ex.info.signal_quality.pass_band_hz;
analysis_channel = ex.info.channels.analysis_channel;

%% Reject artefacts
ex = reject_artefacts(ex,app);

%% Select channels you want to conduct analysis on
kept_trials_channels = ex.kept.channels;
analysis_channel_idx = kept_trials_channels == analysis_channel;
trial_set = ex.kept.trials(analysis_channel_idx,:);
kept_trials_channels = kept_trials_channels(analysis_channel_idx);
ex.kept.jitter = ex.kept.jitter(analysis_channel_idx);

% Check if there are any NaNs
check_for_nans(trial_set,'signal')
check_for_nans(kept_trials_channels,'variable')

%% If we are analyzing more than 1 channel, then apply channel weights
if length(analysis_channel) > 1
[ex, trial_set, channel_weights]  = apply_channel_weights(ex,trial_set,kept_trials_channels);
ex.preprocess(ex.counter.iblock).channel_weights = channel_weights;
ex.kept.trials_weighted = trial_set;

% Check if there are any NaNs
check_for_nans(channel_weights,'variable')
check_for_nans(trial_set,'signal')
end

%% Filter signals
[ex, trial_set] = highpass_filter_signals(ex,fs,pass_band_hz,trial_set);
ex.kept.trials_filtered = trial_set;

% Check if there are any NaNs
check_for_nans(trial_set,'signal')