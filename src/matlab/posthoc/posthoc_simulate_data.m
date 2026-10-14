%% posthoc_simulate_data
% Load in sorted data and get OFF_2f
noise_data = squeeze(org_data.stim_OFF_time(:,:,:,2,:)); % Take subcranial data only (n_trials,n_samples,n_amp,n_chans,n_freq)
noise_data = permute(noise_data,[1 3 4 2]); % put all the dimensions you want to condense onto the left side
noise_data = reshape(noise_data, [],size(noise_data,4)); % reshape/concatenate
noise_data(any(isnan(noise_data), 2),:) = []; % delete rows that have at least one NaN
% Randomize order
rand_idx = randperm(size(noise_data,1));
noise_data = noise_data(rand_idx,:);

% Generate simulated data
make_simulated_aep

% Analyze simulated aep
analyze_simulated_aep