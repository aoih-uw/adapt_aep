function ex = preprocess_signal(ex,app)

fs = ex.info.recording.sampling_rate_hz;
pass_band_hz = ex.info.signal_quality.pass_band_hz;
ex.no_valid_trials = 0;

%% Reject artefacts
if ~strcmp(ex.info.experiment.exp_type,'Timed')
    ex = reject_artefacts(ex,app);
end

%% Adaptive code-specific preprocessing
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    trial_set = ex.kept.trials;
    if ~isempty(trial_set)
        % Check if there are any NaNs
        check_for_nans(trial_set,'signal')
        %% Filter signals
        [ex, trial_set] = highpass_filter_signals(ex,fs,pass_band_hz,trial_set);
        ex.kept.trials_filtered = trial_set;
        % Check if there are any NaNs
        check_for_nans(trial_set,'signal')
    else
        ex.no_valid_trials = 1;
        keyboard
        return
    end
end