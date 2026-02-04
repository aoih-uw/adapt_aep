function ex = filter_signals(ex)
% High pass filter to get rid of low frequency drift
% Higher frequencies don't matter for double frequency response based
% response determination methods
fs = ex.info.recording.sampling_rate_hz;
pass_band_hz= ex.info.signal_quality.pass_band_hz;

kept_trials_weighted = ex.preprocess.kept_trials_weighted;
tic()
kept_trials_filtered = highpass(kept_trials_weighted, pass_band_hz, fs);
time_elapsed = toc();
fprintf('High pass filter processing time: %.3f',time_elapsed)

ex.preprocess.kept_trials_filtered = kept_trials_filtered;