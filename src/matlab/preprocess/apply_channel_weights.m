function ex = apply_channel_weights(ex)
% Apply inverse variance weights to each channel
% Downweight channels that have less consistent signal

kept_trials = ex.preprocess(1).kept_trials;
kept_trials_channels = ex.preprocess(1).kept_channels;
N_channels = ex.info.channels.n_channels;

channel_vars = [];
for ichan = 1:N_channels
    cur_idx = find(kept_trials_channels==ichan);
    cur_channel_trials = kept_trials(cur_idx,:);
    cur_channel_var = mean(var(cur_channel_trials,[],1)); % Calculate sample-by-sample variance across all trials
    channel_vars = [channel_vars cur_channel_var];
end

inverse_vars = 1./channel_vars; % Inverse so larger variances are associated with smaller weights
channel_weights = inverse_vars / sum(inverse_vars); % Now normalize so that all calculated inverse variances add up to 1

fprintf('\nChannel weights: %.3f',channel_weights)

% Create weight vector to apply to `kept_trials`
channel_weight_vec = ones(size(kept_trials_channels,1),size(kept_trials_channels,2));
for ichan = 1:N_channels
    cur_idx = find(kept_trials_channels==ichan);
    channel_weight_vec(cur_idx) = channel_weights(ichan);
end

kept_trials_weighted = kept_trials.*channel_weight_vec;

ex.preprocess(iamp).kept_trials_weighted = kept_trials_weighted;