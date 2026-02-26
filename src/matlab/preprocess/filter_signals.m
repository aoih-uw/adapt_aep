function [ex, kept_trials_filtered] = filter_signals(ex,fs,pass_band_hz,kept_trials_weighted)
% High pass filter to get rid of low frequency drift
% Higher frequencies don't matter for double frequency response based
% response determination methods
tic()
kept_trials_filtered = highpass(kept_trials_weighted, pass_band_hz, fs);
time_elapsed = toc();
fprintf('\nHigh pass filter processing time: %.3f\n',time_elapsed)
