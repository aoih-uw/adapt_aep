%% Load your data first with load_my_file
clearvars my_mean_set my_std_set a_fit k_fit x0_fit my_x_thresh chi2_red grand_fft_vec grand_sorted amp_sorted sorted_idx dy d2y

% 1024 trial specific variables
trials_vec = [16 32 64 128 256 512 1024];
n_it = 1000;
my_chans = [2,3,4]; % 3 = skull pierce, 2 = skin, 1 = EKG , 4 = forebrain
my_mean_set = [];
my_std_set = [];

% My functions
dsoftplus_dx = @(p,x) p(1) ./ (1 + exp(-p(2).*(x - p(3))));

% Extract 1024 related data
for isubj = 1:length(subjid_list)
        f_1 = figure('Visible','off'); t1 = tiledlayout(length(my_chans), length(trials_vec), 'TileSpacing','tight','Padding','tight');
    for ichan = 1:length(my_chans)
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
            for ibatch = 1:n_batches
                clear freq_vec fft_sig
                for itrial = 1:10
                    cur_batch = grand_ex_save{iname,isubj}.raw_signals(1,ibatch).electrodes_microV_ds(itrial,:,cur_chan);
                    [~, freq_vec(itrial,:), fft_sig(itrial,:)] = calc_fft(cur_batch,my_fs(iname,isubj));
                end
                [~, min_idx] = min(abs(freq_vec(1,:)-freq_2f(iname,isubj)));
                diffs_vec = [diffs_vec; fft_sig(:,min_idx)]; % 2f magnitude vector across all batches for a single save file
            end
            grand_fft_vec{iname} = diffs_vec; % Collection of all 2f magnitude vectors across all save files
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
                    rand_select = randperm(size(cur_set,1),cur_trial);
                    tmp_mean = mean(cur_set(rand_select),1);
                    tmp_std = std(cur_set(rand_select),[],1);
                    tmp_it_mean = [tmp_it_mean; tmp_mean];
                    tmp_it_std = [tmp_it_std; tmp_std];
                end
                my_mean_set(:,iname,i_tri,ichan,isubj) = tmp_it_mean;
                my_std_set(:,iname,i_tri,ichan,isubj) = tmp_it_std;
            end

            % Fit and Plot
            for i_it = 1:n_it
                cur_mean = my_mean_set(i_it,:,i_tri,ichan,isubj);
                cur_std = my_std_set(i_it,:,i_tri,ichan,isubj);
                noise_floor = cur_mean(1);

                softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + noise_floor;

                % Find where the signal first exceeds the noise_floor by a
                % fraction of the total range
                signal_range = max(cur_mean) - noise_floor;
                amp_range = max(amp_sorted) - min(amp_sorted);

                rise_idx = find(cur_mean > noise_floor + 0.2*signal_range, 1, 'first');
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

                % Calculate fit
                y_fit = softplus(p, amp_sorted');
                sem = cur_std / sqrt(cur_trial);
                dof = numel(cur_mean) - length(p);
                chi2_red(i_it,i_tri,ichan,isubj) = sum(((y_fit - cur_mean)./sem).^2) / dof;

                % Only look at x_vec where the curve has started rising
                rise_mask = y_vec > noise_floor + 0.1 * (max(y_vec) - noise_floor);
                if any(rise_mask)
                    x_kneedle = x_vec(rise_mask);
                    y_kneedle = y_vec(rise_mask);

                    xn = (x_kneedle - min(x_kneedle)) / (max(x_kneedle) - min(x_kneedle));
                    yn = (y_kneedle - min(y_kneedle)) / (max(y_kneedle) - min(y_kneedle));
                    [~, idx] = max(yn - xn);

                    x_t = x_kneedle(idx);
                    y_t = softplus(p, x_t);  % y value at knee point

                    % Derivative of softplus at x_t: d/dx = a * sigmoid(k*(x - x0))
                    slope = dsoftplus_dx(p, x_t);  % = p(1) / (1 + exp(-p(2)*(x_t - p(3))))

                    % Tangent line: y = slope*(x - x_t) + y_t
                    % Set y = noise_floor and solve for x:
                    x_cross = x_t - (y_t - noise_floor) / slope;

                    my_x_thresh(i_it,i_tri,ichan,isubj) = x_cross;
                else
                    my_x_thresh(i_it,i_tri,ichan,isubj) = NaN;
                end

                if mod(i_it,100) == 0
                    nexttile(t1, (ichan-1)*length(trials_vec) + i_tri)
                    plot(x_vec,y_vec,'Color',[128 128 128]./255,'LineWidth',2);
                    hold on;
                    errorbar(amp_sorted, cur_mean , cur_std,'o-','Color',cur_color)
                    title(sprintf('%d trials', cur_trial))
                    xlabel('Stimulus Amplitude (dB)')
                    ylabel('2f Magnitude (\muV)')
                    xline(my_x_thresh(i_it,i_tri,ichan,isubj),'-','Color',tableau_10('red'))
                    xline(x_t,'-','Color',tableau_10('grey'))
                    yline(noise_floor,'--')
                end
            end
        end
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
        cur_data = my_x_thresh(:,:,ichan,isubj);
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
    figure;tiledlayout('flow','TileSpacing','tight','Padding','tight')
    for iname = 1:length(my_amp(:,isubj))
        nexttile
        for ichan = 1:length(my_chans)
            plot(trials_vec,std(squeeze(my_mean_set(:,iname,:,ichan,1)),[],1,'omitnan'),'-o','LineWidth',2,'MarkerFaceColor','auto');
            title(sprintf('%s dB SPL',string(amp_sorted(iname))))
            hold on;
        end
        ytickformat('%.2f')
        xticks(trials_vec)
        xtickangle(45)
        xlabel('Number of trials included in average')
        ylabel('Standard deviation value')
    end
    
    sgtitle('Standard Deviation of noise of bootstrapped averages')

    % Save figures
    save(sprintf('porichthys_notatus_%s_1024_trial', subjid_list{isubj}), ...
     'my_mean_set', 'my_std_set', 'a_fit', 'k_fit', 'x0_fit', 'my_x_thresh')
end