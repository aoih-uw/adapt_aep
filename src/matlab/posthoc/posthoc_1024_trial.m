%% Load your data first with load_my_file
clearvars my_mean_set my_std_set a_fit k_fit x0_fit my_thresh_0 my_thresh_noise chi2_red grand_fft_vec grand_sorted amp_sorted sorted_idx dy d2y my_snr noise_floor

% 1024 trial specific variables
trials_vec = [16 32 64 128 256 512 1024];
% trials_vec = [1024];
n_it = 1000;
my_chans = [2,3,4]; % 3 = skull pierce, 2 = skin, 1 = EKG , 4 = forebrain
my_mean_set = [];
my_std_set = [];

% My functions
dsoftplus_dx = @(p,x) p(1) ./ (1 + exp(-p(2).*(x - p(3))));

% Waterfall plot initialize
f_water = figure; hold on
tiledlayout(3,1)

% Extract 1024 related data
for isubj = 1:length(subjid_list)
    f_1 = figure('Visible','off'); t1 = tiledlayout(length(my_chans), length(trials_vec), 'TileSpacing','tight','Padding','tight');
    clipped = [];
    for ichan = 1:length(my_chans)
        figure(f_water)
        nexttile
        offset_step = 5;   % vertical spacing between traces - adjust to your data scale
        wcount = 0;
        % Assign channel related vars
        cur_chan = my_chans(ichan);
        if ichan == 1
            cur_color = tableau_10('blue');
        elseif ichan == 2
            cur_color = tableau_10('orange');
        elseif ichan == 3
            cur_color = tableau_10('purple');
        end
        grand_fft_vec = [];
        for iname = 1:length(my_names{isubj})
            diffs_vec = [];
            % Get 2f amplitudes from raw signals
            n_batches = size(grand_ex_save{iname,isubj}.raw_signals,2);
            freq_vec = NaN(10,3529,n_batches);
            fft_sig = NaN(10,3529,n_batches);
            for ibatch = 1:n_batches
                % Load in vars
                latency_samp = grand_ex_save{iname,isubj}.info.recording.latency_samples; % Latency samples not down sampled
                stimulus = grand_ex_save{iname,isubj}.info.stimulus.waveform;
                fs = grand_ex_save{iname,isubj}.ds_fs;
                ds_rate = 2;
                cur_batch_elec = grand_ex_save{iname,isubj}.raw_signals(1,ibatch).electrodes_microV_ds;
                cur_batch_jitter = grand_ex_save{iname,isubj}.block_level_info(1,ibatch).jitter;
                for itrial = 1:10
                    cur_jitter = cur_batch_jitter(itrial);
                    % Get rejected trials
                    if isfield(grand_ex_save{iname, isubj}, 'rejected_trials_post')
                        if ~isempty(grand_ex_save{iname,isubj}.rejected_trials_post)
                            rejected_trials = grand_ex_save{iname,isubj}.rejected_trials_post{:};
                        end
                    elseif ~isempty(grand_ex_save{iname,isubj}.rejected_trials)
                        rejected_trials = grand_ex_save{iname,isubj}.rejected_trials{:};
                    end
                    if ~ismember(itrial+(ibatch-1)*10,rejected_trials) % Don't include artefactual trials in cumulation
                        stim_start = round(cur_jitter/ds_rate + latency_samp/ds_rate + (5/1e3*fs)); % 5 ms off period;
                        stim_end = round(stim_start + length(stimulus)/ds_rate -1);
                        cur_data = cur_batch_elec(itrial,stim_start:stim_end,cur_chan);
                        [~, freq_vec(itrial,:,ibatch), fft_sig(itrial,:,ibatch)] = calc_fft(cur_data,fs);
                    end
                end

                if ~all(any(isnan(fft_sig(:,:,ibatch)),2))
                    valid_rows = ~any(isnan(fft_sig(:,:,ibatch)),2);
                    if ~isempty(find(valid_rows))
                        valid_freq_vec = freq_vec(find(valid_rows,1,'first'),:,ibatch);
                        [~, min_idx] = min(abs(valid_freq_vec-freq_2f(iname,isubj)));
                        diffs_vec = [diffs_vec; fft_sig(valid_rows,min_idx,ibatch)]; % 2f magnitude vector across all batches for a single save file
                    else
                        fprintf('all trials in batch %d, file %d rejected\n',ibatch,iname)
                    end
                end
            end

            %Plot waterfalls
            figure(f_water);
            hold on;
            wcount = wcount + 1;
            y_dat = mean(mean(fft_sig, 1,'omitnan'), 3,'omitnan') + offset_step*wcount;
            plot(valid_freq_vec, y_dat, 'LineWidth',2,'Color',cur_color)
            text(305, offset_step*wcount, string(my_amp(iname)))
            xlim([100,300])
            xline(my_freq(1)*2)

            if ~isempty(diffs_vec)
                grand_fft_vec{iname} = diffs_vec(~any(isnan(diffs_vec),2)); % Collection of all 2f magnitude vectors across all save files
            end
        end

        [amp_sorted, sorted_idx] = sort(my_amp(:,isubj));
        grand_sorted = grand_fft_vec(sorted_idx);

        % Calculate means and std across varied trial counts
        for i_tri = 1:length(trials_vec)
            % Setup figure
            cur_trial = trials_vec(i_tri);
            for iname = 1:length(my_names{isubj})
                cur_set = grand_sorted{iname};
                tmp_it_mean = [];
                tmp_it_std = [];
                for i_it = 1:n_it
                    if size(cur_set,1) < cur_trial
                        fprintf('Only %d trials in %s\n', size(cur_set,1), my_names{isubj}{iname})
                        rand_select = randperm(size(cur_set,1));
                    else
                        rand_select = randperm(size(cur_set,1),cur_trial);
                    end
                    tmp_mean = mean(cur_set(rand_select),1);
                    tmp_std = std(cur_set(rand_select),[],1)/sqrt(size(rand_select,2));
                    tmp_it_mean = [tmp_it_mean; tmp_mean];
                    tmp_it_std = [tmp_it_std; tmp_std];
                end
                if ~isempty(tmp_it_mean)
                    my_mean_set(:,iname,i_tri,ichan,isubj) = tmp_it_mean;
                    my_std_set(:,iname,i_tri,ichan,isubj) = tmp_it_std;
                else
                    my_mean_set(:,iname,i_tri,ichan,isubj) = NaN;
                    my_std_set(:,iname,i_tri,ichan,isubj) = NaN;
                end
            end

            % Fit and Plot
            for i_it = 1:n_it
                cur_mean_non_trans = my_mean_set(i_it,:,i_tri,ichan,isubj);
                noise_floor(i_it,i_tri,ichan,isubj) = cur_mean_non_trans(1);
                cur_mean = sqrt(max(cur_mean_non_trans.^2 - noise_floor(i_it,i_tri,ichan,isubj).^2, 0));
                cur_std = my_std_set(i_it,:,i_tri,ichan,isubj);

                softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + cur_mean(1) ;

                % Find where the signal first exceeds the noise_floor by a
                % fraction of the total range
                signal_range = max(cur_mean) - noise_floor(i_it,i_tri,ichan,isubj) ;
                amp_range = max(amp_sorted) - min(amp_sorted);

                rise_idx = find(cur_mean > noise_floor(i_it,i_tri,ichan,isubj)  + 0.2*signal_range, 1, 'first');
                if isempty(rise_idx)
                    rise_idx = round(length(amp_sorted)/2);
                end
                x0_init = amp_sorted(rise_idx);
                upper_span = max(max(amp_sorted) - x0_init, 0.1*amp_range);

                a_init = (max(cur_mean) - cur_mean(rise_idx)) / upper_span; % Slope of the upper arrm
                k_init = 4 / upper_span;
                p0 = [a_init,k_init,x0_init];

                lb = [0, 0.5/upper_span, min(amp_sorted)];   % keep k off 0
                ub = [Inf, 10/upper_span, max(amp_sorted)-5];  % cap knee sharpness

                p = lsqcurvefit(softplus,p0,amp_sorted',cur_mean,lb,ub,optimset('Display','off'));

                a_fit(i_it,i_tri,ichan,isubj) = p(1);
                k_fit(i_it,i_tri,ichan,isubj) = p(2);
                x0_fit(i_it,i_tri,ichan,isubj) = p(3);

                x_vec = linspace(min(amp_sorted),max(amp_sorted),200);
                y_vec = softplus(p,x_vec);

                slope_frac = 0.05; % fraction of max slope defining "end of lower asymptote"
                x_lower_end(i_it,i_tri,ichan,isubj) = p(3) + (1/p(2))*log(slope_frac/(1-slope_frac));

                % Only look at x_vec where the curve has started rising
                rise_mask = y_vec > noise_floor(i_it,i_tri,ichan,isubj)  + 0.1 * (max(y_vec) - noise_floor(i_it,i_tri,ichan,isubj) );
                if any(rise_mask)
                    x_kneedle = x_vec(rise_mask);
                    y_kneedle = y_vec(rise_mask);

                    xn = (x_kneedle - min(x_kneedle)) / (max(x_kneedle) - min(x_kneedle)); % normalize all x values from 0-1
                    yn = (y_kneedle - min(y_kneedle)) / (max(y_kneedle) - min(y_kneedle)); % normalize all y values from 0-1
                    [~, idx] = max(yn - xn); % find where yn differs from xn the most

                    x_t = x_kneedle(idx);
                    y_t = softplus(p, x_t);  % y value at knee point

                    % Derivative of softplus at x_t: d/dx = a * sigmoid(k*(x - x0))
                    slope = dsoftplus_dx(p, x_t);  % = p(1) / (1 + exp(-p(2)*(x_t - p(3))))

                    % Tangent line: y = slope*(x - x_t) + y_t
                    % Set y = noise_floor and solve for x:
                    x_cross_noise = x_t - (y_t - noise_floor(i_it,i_tri,ichan,isubj) ) / slope;
                    x_cross_0 = x_t - (y_t - 0) / slope;

                    my_thresh_noise(i_it,i_tri,ichan,isubj) = x_cross_noise;
                    my_thresh_0(i_it,i_tri,ichan,isubj) = x_cross_0;
                else
                    my_thresh_noise(i_it,i_tri,ichan,isubj) = x_cross_noise;
                    my_thresh_0(i_it,i_tri,ichan,isubj) = NaN;
                end

                % Run plot_derivatives from here

                if mod(i_it,100) == 0
                    nexttile(t1, (ichan-1)*length(trials_vec) + i_tri)
                    plot(x_vec,y_vec,'Color',[128 128 128]./255,'LineWidth',2);
                    hold on;
                    errorbar(amp_sorted, cur_mean , cur_std,'o-','Color',cur_color)
                    title(sprintf('%d trials', cur_trial))
                    xlabel('Stimulus Amplitude (dB)')
                    ylabel('2f Magnitude (\muV)')
                    xline(x0_fit(i_it,i_tri,ichan,isubj), '--', 'Color',tableau_10('green'))
                    % xline(my_thresh_noise(i_it,i_tri,ichan,isubj),'-','Color',tableau_10('red'))
                    xline(x_lower_end(i_it,i_tri,ichan,isubj),'--','Color',tableau_10('red'))
                    % xline(x_t,'-','Color',tableau_10('grey'))
                    yline(noise_floor(i_it,i_tri,ichan,isubj) ,'--')
                end
            end
        end
        figure(f_water);
    title(string(cur_chan))
    end
    % Set titles
    figure(f_1);
    sgtitle('Threshold estimate varied by N trials included in average')

    set([f_1],'Visible','on')
    
    % Plot variance of threshold estimates per channel
    figure;
    for ichan = 1:length(my_chans)
        if ichan == 1
            cur_color = tableau_10('blue');
        elseif ichan == 2
            cur_color = tableau_10('orange');
        elseif ichan == 3
            cur_color = tableau_10('purple');
        end
        cur_data = x_lower_end(:,:,ichan,isubj);
        tmp_mean = mean(cur_data,1,'omitnan');
        tmp_std = std(cur_data,[],1,'omitnan');
        errorbar(trials_vec,tmp_mean,tmp_std,'o-','LineWidth',2,'Color',cur_color)
        xticks(trials_vec)
        xtickangle(45)
        xscale('linear')
        hold on;
    end
    legend(string(my_chans))
    title('How much does threshold estimation vary by trial number and by channel number')

    % Plot how noise reduced over time
    figure; tiledlayout('flow','TileSpacing','tight','Padding','tight')
    for iname = 1:length(my_amp(:,isubj))
        nexttile
        for ichan = 1:length(my_chans)
            errorbar(trials_vec,mean(squeeze(my_std_set(:,iname,:,ichan,isubj))), std(squeeze(my_std_set(:,iname,:,ichan,isubj)),[],1),'-o','LineWidth',2,'MarkerFaceColor','auto');
            title(sprintf('%s dB SPL',string(amp_sorted(iname))))
            hold on;
        end
        ytickformat('%.2f')
        xticks(trials_vec)
        xtickangle(45)
        xlabel('Number of trials included in average')
        ylabel('Standard error value')
    end
    sgtitle('Standard error of noise of bootstrapped averages')


    % Plot SNR
    % figure;
    % [~, my_max_idx] = max(amp_sorted);
    % [~, my_min_idx] = min(amp_sorted);
    % for ichan = 1:length(my_chans)
    %     my_sig   = mean(squeeze(my_mean_set(:, my_max_idx, :, ichan, isubj)), 1);
    %     my_noise = mean(squeeze(my_mean_set(:, my_min_idx, :, ichan, isubj)), 1);
    %     my_snr(ichan,:) = (my_sig - my_noise) ./ my_noise;
    %     plot(1:length(trials_vec), my_snr(ichan,:),'o-')
    %     hold on;
    % end

    % Save figures
    save(sprintf('porichthys_notatus_%s_1024_trial', subjid_list{isubj}), ...
        'my_mean_set', 'my_std_set', 'a_fit', 'k_fit', 'x0_fit', 'my_thresh_0', 'my_thresh_noise')
end