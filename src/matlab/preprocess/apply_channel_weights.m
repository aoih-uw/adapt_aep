function [ex, kept_trials_weighted, channel_weights] = apply_channel_weights(ex,kept_trials,kept_trials_channels)
% Apply inverse variance weights to each channel
%# Check logic of this math
% Downweight channels that have less consistent signal

N_channels = ex.info.channels.n_channels;

channel_vars = [];
for ichan = 1:N_channels
    cur_idx = find(kept_trials_channels==ichan);
    if ~isempty(cur_idx) % Only do this for channels we have data for/havent been removed
    cur_channel_trials = kept_trials(cur_idx,:);
    valid_cols = ~all(isnan(cur_channel_trials), 1); %# if a whole column is nan then skip it in the calculation of variance there is nothing to work with. (because of jitter size making each trial a different length, and padding with NaNs)
    cur_channel_trials = cur_channel_trials(:,valid_cols);
    cur_channel_var = mean(var(cur_channel_trials,[],1,'omitnan'),2,'omitnan'); % Calculate sample-by-sample variance across all trials, then take the mean for each channel
    channel_vars = [channel_vars cur_channel_var];
    end
end

inverse_vars = 1./channel_vars; % Inverse so larger variances are associated with smaller weights
channel_weights = inverse_vars / sum(inverse_vars); % Now normalize so that all calculated inverse variances add up to 1

fprintf('\nChannel weights: %s\n', num2str(channel_weights, '%.3f '));

% Create weight vector to apply to `kept_trials`
channel_weight_vec = ones(size(kept_trials_channels,1),size(kept_trials_channels,2));
for ichan = 1:N_channels
    cur_idx = find(kept_trials_channels==ichan);
    if ~isempty(cur_idx) % If it is empty don't do anything
        channel_weight_vec(cur_idx) = channel_weights(ichan);
    end
end

kept_trials_weighted = kept_trials.*channel_weight_vec;