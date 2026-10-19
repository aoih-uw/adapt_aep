%% fit_simulated_models
% input: my_results.F_stats
figure;
F_stats = my_results.F_stats; %([F p], n_freq, n_amps, n_batches, n_reps)
trials_per_block = 10;
max_trials = size(F_stats,4);
my_alpha = 0.05/size(F_stats,4);
log_trans_alpha = log10(finv(1 - my_alpha, 2, 2*(2*max_trials - 2)));
amp_vec = snr_dB_vec;
amp_vec(1) = -54;
true_thresh = -49.5;
thresholds = NaN(size(F_stats,5),1);
for irep = 1:size(F_stats,5)
    for ifreq = 1:size(F_stats,2)
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

        plot(x_vec,y_vec,'Color',[tableau_10('blue') 0.2],'LineWidth',.5);
        
        hold on;
        % plot(amp_vec,cur_y,'o-');

        % Identify threshold
        idx = find(y_vec > log_trans_alpha,1,'first');
        thresholds(irep) = x_vec(idx);
        yline(log_trans_alpha)
    end
end
xline(true_thresh)
title('F stat model fit');
xlabel('SNR (dB)'); ylabel('log10(F)')
xlabel('SNR (dB)'); ylabel('Frequency')
% Thresholds
median_threshold = median(thresholds);
median_threshold_error = median_threshold - (true_thresh);
figure;histogram(thresholds,'FaceColor',tableau_10('blue'));
xline(true_thresh);
title(sprintf('Threshold estimates | Median error: %g dB', median_threshold_error));
xlabel('SNR (dB)'); ylabel('Frequency')