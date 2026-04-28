function [ex, kept_trials_filtered] = highpass_filter_signals(ex,fs,pass_band_hz,kept_trials_weighted)
% High pass filter to get rid of low frequency drift
% Higher frequencies don't matter for double frequency response based
% response determination methods
tic()

% Design filter ONCE outside the loop
filter_order = 4; % adjust as needed
[b, a] = butter(filter_order, pass_band_hz / (fs/2), 'high');

kept_trials_filtered = nan(size(kept_trials_weighted));

for itrial = 1:size(kept_trials_weighted, 1)
    row = kept_trials_weighted(itrial, :);
    nan_idx = isnan(row); %# figure what this doing

    if all(nan_idx)
        continue
    end

    % Interpolate over NaNs temporarily
    row_filled = row;
    row_filled(nan_idx) = interp1(find(~nan_idx), row(~nan_idx), find(nan_idx), 'linear', 'extrap');

    % Apply pre-designed filter (much faster than highpass())
    row_filtered = filtfilt(b, a, row_filled);

    % Restore NaNs
    row_filtered(nan_idx) = NaN;
    kept_trials_filtered(itrial, :) = row_filtered;
end

time_elapsed = toc();
fprintf('\nHigh pass filter processing time: %.3f s\n', time_elapsed)
