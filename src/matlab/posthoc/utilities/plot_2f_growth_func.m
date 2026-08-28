function [growth_func_mean, growth_func_sem, growth_func_noise_floor] = ...
    plot_2f_growth_func(cumu, resp_found_vec, amp_vec, my_chans, my_chans_name, ...
                        trials_per_block, cur_freq, use_sigmoid, plot_linear)

%% 2f based growth function (SOFTPLUS)
   %% Generate vector simulating live experiment with uneven trial counts based on bootstrap decisions
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            cur_idx = resp_found_vec(ichan,iamp,end,end)/trials_per_block;
            if isnan(cur_idx) % Get the mean and sem of the last measured batch
                growth_func_mean(ichan,iamp) = cumu.diff_mean_2f(end,iamp,ichan);
                growth_func_sem(ichan,iamp) = cumu.diff_sem_2f(end,iamp,ichan);
                growth_func_noise_floor(ichan,iamp) = cumu.noise_floor_mean_2f(end,iamp,ichan);
            else % Get the valid resp_found idx and extract its mean/sem
                growth_func_mean(ichan,iamp) = cumu.diff_mean_2f(cur_idx,iamp,ichan);
                growth_func_sem(ichan,iamp) = cumu.diff_sem_2f(cur_idx,iamp,ichan);
                growth_func_noise_floor(ichan,iamp) = cumu.noise_floor_mean_2f(cur_idx,iamp,ichan);
            end
        end
    end

    % Plot 2f growth functions
    figure; tiledlayout(1,length(my_chans),'Padding','tight','TileSpacing','tight');
    for ichan = 1:length(my_chans)
        nexttile
        cur_color = select_chan_color(ichan);
        cur_y = growth_func_mean(ichan,:);
        cur_y_sem = growth_func_sem(ichan,:);
        cur_noise_floor = median(growth_func_noise_floor(ichan,:));

        % Fit model
        if use_sigmoid
            % Fit sigmoid
            [p, cur_data, cur_data_sem, logistic] = param_logistic(cur_y, cur_y_sem, amp_vec, []);
            x_vec = linspace(min(amp_vec),max(amp_vec),200);
            y_vec = logistic(p, x_vec);
        else
            % Fit softplus
            [p, cur_data, cur_data_sem, softplus] = param_softplus(cur_y,cur_y_sem,amp_vec, [],0); % Fit to the raw data without correction
            x_vec = linspace(min(amp_vec),max(amp_vec),200);
            y_vec = softplus(p, x_vec);
        end

        % Plot raw data
        errorbar(amp_vec,cur_y,cur_y_sem,'o','Color',cur_color,'MarkerFaceColor',cur_color,'LineWidth',2);
        hold on;

        % Plot fitted curve
        plot(x_vec,y_vec,'-','Color',cur_color,'LineWidth',2);
        xticks(amp_vec)
        xlabel('Stimulus amplitude')
        ylabel('Amplitude (\muV)')
        title(my_chans_name{ichan})
    end
    sgtitle(sprintf('%d Hz: Simulated Adaptive 2f Growth Functions (Softplus)',cur_freq));
    linkaxes

    if plot_linear
    %% Plot 2f based growth functions - linear fit
    figure; tiledlayout(1,length(my_chans),'Padding','tight','TileSpacing','tight');
    for ichan = 1:length(my_chans)
        nexttile
        cur_color = select_chan_color(ichan);
        cur_y = growth_func_mean(ichan,:);
        cur_y_sem = growth_func_sem(ichan,:);

        % Fit linear regression
        keep = ~isnan(cur_y);
        p_lin = polyfit(amp_vec(keep), cur_y(keep), 1);
        x_vec = linspace(min(amp_vec),max(amp_vec),200);
        y_vec = polyval(p_lin, x_vec);

        errorbar(amp_vec,cur_y,cur_y_sem,'o','Color',cur_color,'MarkerFaceColor',cur_color,'LineWidth',2);
        hold on;
        plot(x_vec,y_vec,'-','Color',cur_color,'LineWidth',2);
        xticks(amp_vec)
        xlabel('Stimulus amplitude')
        ylabel('Amplitude (\muV)')
        title(string(ichan))
    end
    sgtitle(sprintf('%d Hz: Simulated Adaptive 2f Growth Functions (Linear)',cur_freq));
    linkaxes
    end
