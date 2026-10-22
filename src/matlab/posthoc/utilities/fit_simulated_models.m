%% fit_simulated_models
% input: my_results.F_stats
F_stats = my_results.F_stats; %([F p], n_freq, n_amps, n_batches, n_reps)
trials_per_block = 10;
max_trials = size(F_stats,4);
log_trans_alpha = log10(finv(1 - my_alpha, 2, 2*(max_trials - 1)));
amp_vec = snr_dB_vec;
freq_inc = ex.info.mixed.stim_freqs;
thresholds = NaN(size(F_stats,5),numel(freq_inc));

% "True threshold" is completely defined by the amplitude sampling
% resolution we chose, it is only the last amplitude we saw a response
true_thresh = -23.5;

% Model fit accuracy appears to be dependent on the lower asymptote, test
% this directly
as_vec = linspace(-23.6,-100,50);
median_threshold_error = NaN(numel(as_vec),numel(freq_inc));

% Loop through
for ias = 1:numel(as_vec)
    ias
    amp_vec(1) = as_vec(ias); % Setting the lower asymptote is critical
    if ismember(ias,[1 10 50])
        figure; tiledlayout(3,2,'TileSpacing','tight','Padding','tight');
    end
    for ifreq = 1:size(F_stats,2)
        if ismember(ias,[1 10 50])
            nexttile
        end
        cur_color = select_chan_color(ifreq);
        for irep = 1:size(F_stats,5)
            cur_data = squeeze(F_stats(1,ifreq,:,:,irep));
            trials_needed = F_first(ifreq,:,irep); % Trials needed to find a response
            % Build the growth function vectors
            cur_idx = trials_needed/trials_per_block;
            cur_y = [];
            for i = 1:length(cur_idx)
                % Get the valid resp_found idx and extract its mean/sem
                tmp_idx = cur_idx(i);
                cur_y = [cur_y cur_data(i,tmp_idx)];
            end
            cur_y = log10(max(cur_y,realmin,'includenan'));

            [p, logistic, fq] = param_logistic(cur_y, amp_vec);

            x_vec = linspace(min(amp_vec),max(amp_vec),2000);
            y_vec = logistic(p,x_vec);

            % Identify threshold
            idx = find(y_vec > log_trans_alpha,1,'first');
            thresholds(irep,ifreq) = x_vec(idx);

            if ismember(ias,[1 10 50])
                plot(x_vec,y_vec,'Color',[cur_color 0.2],'LineWidth',.5);
                hold on;
                yline(log_trans_alpha)
            end
        end
        % Calculate threshold estimation error
        median_threshold = median(thresholds(:,ifreq));
        median_threshold_error(ias,ifreq) = median_threshold - (true_thresh);

        if ismember(ias,[1 10 50])
            xline(true_thresh)
            title(sprintf('%d Hz',freq_inc(ifreq)));
            xlabel('SNR (dB)'); ylabel('log10(F)')

            % Threshold histograms
            nexttile
            histogram(thresholds,'FaceColor',cur_color);
            xline(true_thresh);
            title(sprintf('Error: %g dB', median_threshold_error(ias,ifreq)));
            xlabel('SNR (dB)'); ylabel('Frequency')

            % Label whole figure
            sgtitle(sprintf('amp_vec(1) = %g', as_vec(ias)))
        end

    end
end

% Best lower asymptote
figure;
tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
for ifreq = 1:numel(freq_inc)
    nexttile
    cur_color = select_chan_color(ifreq);
    plot(as_vec, median_threshold_error(:,ifreq),'-o','Color',cur_color,'MarkerFaceColor',cur_color);
    hold on;
    yline(0,'--')
    xlabel('amp_vec(1) value')
    ylabel('Error (dB)')
    [~,idx] = min(abs(median_threshold_error(:,ifreq)));
    dist_from_tru = as_vec(idx)-true_thresh;
    title(sprintf('%d Hz | %g',freq_inc(ifreq),dist_from_tru))
end
linkaxes
sgtitle('What is the lowest stimulus amplitude the model should include?')