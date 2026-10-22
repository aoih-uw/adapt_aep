%% posthoc_simulate_data
% Assign variables
% Latency samples are added to the end of the trial in
% make_scaled_jittered_stim_block, and since we are using the waveforms
% that come out from this function directly (rather than a waveform that
% came through the DAC from a live fish, which in this case the latency
% padding would occur at the beginning) we shouldn't take into account
% latency for this simulated data
%% subject_44_Mixed freqs_20261013 is the only file that has the stim_OFF_time field... so use this file
latency_samples = 0;

% Number of times you want to run this simulation
n_rep = 50;
pre_alpha = 0.01;

%% What "stimulus amplitudes" do you want to simulate?
% signal_scale = linspace(0,0.05,16);
signal_scale = linspace(0,1,16);

% Load in sorted data and get OFF_2f
setup_noise_data
clear my_results
for irep = 1:n_rep
    fprintf('--- %d ---\n',irep)
    %% Randomise order of noise_data
    rand_idx = randperm(size(noise_data,1));
    noise_data = noise_data(rand_idx,:);

    %% Create simulated data
    fprintf('Creating simulated AEPs...\n')
    tic()
    make_simulated_aep
    toc()

    % Setup vars after make_simulated_aep
    snr_dB_vec = 20.*log10(snr_vec);
    my_alpha = pre_alpha / (n_trials/trials_per_block);

    %% Preallocate analysis results fields
    fprintf('Analyzing simulated AEPs...\n')
    tic()
    % Preallocate analysis vars
    % Setup only once
    if irep == 1
        F_first = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale),n_rep);
        F_stable = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale),n_rep);
        F_inconsist = NaN(numel(ex.info.mixed.stim_freqs), numel(signal_scale),n_rep);

        my_results.F_stats = NaN(2, numel(ex.info.mixed.stim_freqs), numel(signal_scale), (n_trials/trials_per_block),n_rep);
    end

    % Simulate batched AEP
    for ifreq = 1:size(ex.info.stimulus,2)
        cur_freq = ex.info.mixed.stim_freqs(ifreq)*2;
        period_length_samples = length(ex.info.stimulus(ifreq).waveform);
        ramp_duration_samples = (ex.info.stimulus(ifreq).ramp_duration_ms)/1000*fs;
        for iamp = 1:length(signal_scale)
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

            % Simulate live aep batches and calculation of F
            for ibatch = 1:(n_trials/trials_per_block)
                % Cumulative row selection
                cur_rows = 1:trials_per_block*ibatch;

                % Calc_F_stat output: [F p]
                my_F_stats = calc_F_stat_2samp(ON_2f(cur_rows),OFF_2f(cur_rows));

                % Store results
                my_results.F_stats(:,ifreq,iamp,ibatch,irep) = my_F_stats';
            end
        end
    end

    %% Find first/stable responses
    for ifreq = 1:size(ex.info.stimulus,2)
        for iamp = 1:length(signal_scale)
            % F stat based
            cur_data = squeeze(my_results.F_stats(2,ifreq,iamp,:,irep));
            n_filled = find(~isnan(cur_data),1,'last');
            cur_data = cur_data(1:n_filled) < my_alpha;
            [cur_first, cur_stable, cur_inconsist] = find_first_stable(cur_data, n_filled,n_trials,trials_per_block);
            F_first(ifreq,iamp,irep) = cur_first;
            F_stable(ifreq,iamp,irep) = cur_stable;
            F_inconsist(ifreq,iamp,irep) = cur_inconsist;
        end
    end
end

%% Difference map
F_diff_median = median(F_stable,3,'omitnan')-median(F_first,3,'omitnan');
F_diff_mad = mad(F_stable-F_first,1,3);

%% Calculate false positive rate
no_sig = squeeze(F_first(:,1,:));
false_pos = find(no_sig < 1030);
first_false_pos_rate = (numel(false_pos)/numel(no_sig))*100;

no_sig = squeeze(F_stable(:,1,:));
false_pos = find(no_sig < 1030);
stable_false_pos_rate = (numel(false_pos)/numel(no_sig))*100;

false_pos_rate.first = first_false_pos_rate;
false_pos_rate.stable = stable_false_pos_rate;

%% Plot trial count heatmaps
all_data = {F_first, F_stable, F_inconsist, F_diff_median};
all_titles = {'F-test: First Response', 'F-test: Stable Response', 'F-test: Inconsistent', 'F-test: Stable-First'};

cmap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
for i = 1:numel(all_data)
    if strcmp(all_titles{i},'F-test: Stable-First')
        M = F_diff_median;
        D = F_diff_mad;
    else
        M = median(all_data{i},3,'omitnan');
        D = mad(all_data{i},1,3);
    end
    figure;
    imagesc(M,'AlphaData',~isnan(M));
    colormap(gca,cmap);
    xlbl = compose('%.1f',snr_dB_vec); xlbl(isinf(snr_dB_vec)) = {'Noise only'};
    set(gca,'Color',tableau_10('grey'),'TickLength',[0 0], ...
        'XTick',1:numel(snr_dB_vec),'XTickLabel',xlbl, ...
        'YTick',1:numel(ex.info.mixed.stim_freqs),'YTickLabel',string(ex.info.mixed.stim_freqs));
    for k = find(~isnan(M))'
        [r,c] = ind2sub(size(M),k);
        text(c,r-0.15,sprintf('%g',M(k)),'HorizontalAlignment','center','FontSize',12);
        text(c,r+0.22,sprintf('%g',D(k)),'HorizontalAlignment','center','FontSize',8,'Color',[.4 .4 .4]);
    end
    title(all_titles{i}); xlabel('SNR (dB)'); ylabel('Stimulus Frequency (Hz)');
    if strcmp(all_titles{i},'F-test: First Response')
        subtitle(sprintf('False + rate: %g%%',first_false_pos_rate))
    elseif strcmp(all_titles{i},'F-test: Stable Response')
        subtitle(sprintf('False + rate: %g%%',stable_false_pos_rate))
    end
end

%% Plot models
fit_simulated_models

%% Save results
stim_freqs = ex.info.mixed.stim_freqs;
save(sprintf('posthoc_sim_results_%s.mat', datestr(now,'yyyymmdd_HHMMSS')), ...
    'my_results','F_first','F_stable','F_inconsist','false_pos_rate', ...
    'snr_dB_vec','signal_scale','stim_freqs', ...
    'n_rep','n_trials','trials_per_block','my_alpha');
