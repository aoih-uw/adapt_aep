%% analyze_simulated_aep
% Assign variables
fs = ex.info.DAC.sampling_rate_hz;
latency_samples = ex.info.DAC.latency_samples;
my_alpha = 0.01;
snr_vec = snr_mat(ifreq,:,ibatch);
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

% Simulate bootstrapping % CHECK THIS CODE %#%#
n_batches = n_trials/trials_per_block;
for ifreq = 1:size(ex.info.stimulus,2)
    cur_freq = ex.info.mixed.stim_freqs(ifreq)*2;
    period_length_samples = length(ex.info.stimulus(ifreq).waveform);
    ramp_duration_samples = ex.info.stimulus(ifreq).ramp_duration_ms/1000*fs;
    for iamp = 1:length(signal_scale)
        cur_batch = simulated_aep(:,:,ifreq,iamp,:);
        cur_batch = reshape(permute(cur_batch,[1 5 2 3 4]), [], size(cur_batch,2));
        cur_jitter = reshape(permute(jitter_mat(:,1,ifreq,iamp,:),[1 5 2 3 4]), [], 1);
        [ON,OFF] = extract_stim_ON_OFF(cur_batch,1,fs,latency_samples,period_length_samples, ...
            ramp_duration_samples, [], cur_jitter);
        [freq_vec,~] = calc_fft_complex(ON(1,:),fs);
        [~,idx] = min(abs(freq_vec - cur_freq));
        ON_2f = zeros(size(ON,1),1);
        OFF_2f = zeros(size(OFF,1),1);
        for itrial = 1:size(ON,1)
            [~,tmp] = calc_fft_complex(ON(itrial,:),fs);  
            ON_2f(itrial) = tmp(idx);
            [~,tmp] = calc_fft_complex(OFF(itrial,:),fs); 
            OFF_2f(itrial) = tmp(idx);
        end
        n_per_batch = size(ON,1)/n_batches;
        for ibatch = 1:n_batches
            rows = 1:ibatch*n_per_batch;
            [~, my_results.lower_CI(ifreq,iamp,ibatch)] = calculate_bootstrap(5000, ON_2f(rows), OFF_2f(rows), 99);
            my_results.F_stats(:,ifreq,iamp,ibatch) = calc_F_stat_2samp(ON_2f(rows),OFF_2f(rows));
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