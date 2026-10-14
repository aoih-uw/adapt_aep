%% analyze_simulated_aep
% Assign variables
fs = ex.info.DAC.sampling_rate_hz;
% Latency samples are added to the end of the trial in
% make_scaled_jittered_stim_block, and since we are using the waveforms
% that come out from this function directly (rather than a waveform that
% came through the DAC from a live fish, which in this case the latency
% padding would occur at the beginning) we shouldn't take into account
% latency for this simulated data
latency_samples = 0;
my_alpha = 0.01;
snr_vec = snr_mat(1,:,1);
snr_dB_vec = 20.*log10(snr_vec);

% Should already be loaded in
% signal_scale;
% trials_per_block;
% n_trials;

% Preallocate vars
my_results.lower_CI = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale), (n_trials/trials_per_block));
my_results.F_stats = NaN(2, numel(ex.info.mixed.stim_freqs), numel(signal_scale), (n_trials/trials_per_block));

boot_first = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale));
boot_stable = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale));
boot_inconsist = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale));

F_first = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale));
F_stable = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale));
F_inconsist = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale));

% Simulate bootstrapping
for ifreq = 1:size(ex.info.stimulus,2)
    cur_freq = ex.info.mixed.stim_freqs(ifreq)*2;
    period_length_samples = length(ex.info.stimulus(ifreq).waveform);
    ramp_duration_samples = (ex.info.stimulus(ifreq).ramp_duration_ms)/1000*fs;
    for iamp = 1:length(signal_scale)
        cur_scale_fac = signal_scale(iamp);

        % Get all trials
        cur_data = squeeze(simulated_aep(:,:,ifreq,iamp,:));
        cur_data = reshape(permute(cur_data,[1 3 2]), [], size(cur_data,2));

        % Jitter
        cur_jitter = squeeze(jitter_mat(:,1,ifreq,iamp,:));
        cur_jitter = reshape(cur_jitter, [], 1);

        % Extract ON/OFF periods
        [ON,OFF] = extract_stim_ON_OFF(cur_data,1,fs,latency_samples,period_length_samples, ...
            ramp_duration_samples, [], cur_jitter);

        % Calculate fft across all available trials
        ON_complex = NaN(size(ON,1),ceil(size(ON,2)/2)+1);
        OFF_complex = NaN(size(OFF,1),ceil(size(OFF,2)/2)+1);
        for itrial = 1:size(ON,1)
            cur_ON = ON(itrial,:);
            cur_OFF = OFF(itrial,:);
            [freq_vec,tmp_ON] = calc_fft_complex(cur_ON,fs);
            [~,tmp_OFF] = calc_fft_complex(cur_OFF,fs);
            ON_complex(itrial,:) = tmp_ON;
            OFF_complex(itrial,:) = tmp_OFF;
        end

        % Select 2f bin across all available trials
        [~, idx] = min(abs(freq_vec - cur_freq));
        ON_2f = ON_complex(:,idx);
        OFF_2f = OFF_complex(:,idx);

        % Simulate live aep batches and calculation of F and bootstat
        for ibatch = 1:(n_trials/trials_per_block)
            % Cumulative row selection
            cur_rows = 1:trials_per_block*ibatch;
            % Calculate bootstrap
            [bootstat, lower_CI] = calculate_bootstrap(5000, ON_2f(cur_rows),OFF_2f(cur_rows), 99);

            % Calc_F_stat output: [myPLV, R F p]
            my_F_stats = calc_F_stat_2samp(ON_2f(cur_rows),OFF_2f(cur_rows));

            % Store results
            my_results.lower_CI(ifreq,iamp,ibatch) = lower_CI;
            my_results.F_stats(:,ifreq,iamp,ibatch) = my_F_stats';
        end
    end
end

% Find first/stable responses
for ifreq = 1:size(ex.info.stimulus,2)
    for iamp = 1:length(signal_scale)
        
        % Bootstrap based
        cur_data = squeeze(my_results.lower_CI(ifreq,iamp,:));
        n_filled = find(~isnan(cur_data),1,'last');
        cur_data = cur_data(1:n_filled) > 0;
        [cur_first, cur_stable, cur_inconsist] = find_first_stable(cur_data, n_filled,n_trials,trials_per_block);
        boot_first(ifreq,iamp) = cur_first;
        boot_stable(ifreq,iamp) = cur_stable;
        boot_inconsist(ifreq,iamp) = cur_inconsist;
        
        % F stat based
        cur_data = squeeze(my_results.F_stats(2,ifreq,iamp,:));
        n_filled = find(~isnan(cur_data),1,'last');
        cur_data = cur_data(1:n_filled) < my_alpha;
        [cur_first, cur_stable, cur_inconsist] = find_first_stable(cur_data, n_filled,n_trials,trials_per_block);
        F_first(ifreq,iamp) = cur_first;
        F_stable(ifreq,iamp) = cur_stable;
        F_inconsist(ifreq,iamp) = cur_inconsist;
    end
end

%% Ploting code %# FIX / CHANGE
%% Plot trial count heatmaps
all_data = {boot_first, boot_stable, boot_inconsist, F_first, F_stable, F_inconsist};
all_titles = {'Bootstrap: First Response', 'Bootstrap: Stable Response', 'Bootstrap: Inconsistent', ...
    'F-test: First Response', 'F-test: Stable Response', 'F-test: Inconsistent'};
for i = 1:numel(all_data)
    figure;
    cur_data = all_data{i};
    cur_data(cur_data == n_trials) = NaN;
    h = heatmap(cur_data);
    h.MissingDataColor = tableau_10('grey');
    h.XDisplayLabels = compose('%.3f', snr_dB_vec);
    h.YDisplayLabels = string(ex.info.mixed.stim_freqs);
    h.ColorbarVisible = 'off';
    h.Colormap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
    title(all_titles{i})
    h.XLabel = 'SNR (dB)';
    h.YLabel = 'Stimulus Frequency (Hz)';
end