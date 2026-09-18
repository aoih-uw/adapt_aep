function [twof_growth_func] = ...
    plot_2f_growth_func(cumu, resp_found_vec, amp_vec, my_chans, my_chans_name, ...
    trials_per_block, cur_freq, use_sigmoid, plot_linear)
%% 2f based growth function (SOFTPLUS)
my_reso = 200;

% Preallocate
twof_growth_func.mean = NaN(length(my_chans),length(amp_vec));
twof_growth_func.sem = NaN(length(my_chans),length(amp_vec));
twof_growth_func.noise_floor = NaN(length(my_chans),length(amp_vec));
twof_growth_func.x_vec = NaN(1,my_reso,length(my_chans));
twof_growth_func.y_vec = NaN(1,my_reso,length(my_chans));

%% Generate vector simulating live experiment with uneven trial counts based on bootstrap decisions
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        cur_idx = resp_found_vec(ichan,iamp,end,end)/trials_per_block;

        if isnan(cur_idx) % Get the mean and sem of the last measured batch
            twof_growth_func.mean(ichan,iamp) = cumu.diff_mean_2f(end,iamp,ichan);
            twof_growth_func.sem(ichan,iamp) = cumu.diff_sem_2f(end,iamp,ichan);
            twof_growth_func.noise_floor(ichan,iamp) = cumu.noise_floor_mean_2f(end,iamp,ichan);
        else % Get the valid resp_found idx and extract its mean/sem
            twof_growth_func.mean(ichan,iamp) = cumu.diff_mean_2f(cur_idx,iamp,ichan);
            twof_growth_func.sem(ichan,iamp) = cumu.diff_sem_2f(cur_idx,iamp,ichan);
            twof_growth_func.noise_floor(ichan,iamp) = cumu.noise_floor_mean_2f(cur_idx,iamp,ichan);
        end
    end
end

% Plot 2f growth functions
figure; tiledlayout(1,length(my_chans),'Padding','tight','TileSpacing','tight');
for ichan = 1:length(my_chans)
    nexttile
    cur_color = select_chan_color(ichan);
    cur_y = twof_growth_func.mean(ichan,:);
    cur_y_sem = twof_growth_func.sem(ichan,:);

    % Fit model
    if use_sigmoid
        % Fit sigmoid
        [p, cur_data, cur_data_sem, logistic] = param_logistic(cur_y, cur_y_sem, amp_vec, []);
        x_vec = linspace(min(amp_vec),max(amp_vec),my_reso);
        y_vec = logistic(p, x_vec);
    else
        % Fit softplus
        [p, cur_data, cur_data_sem, softplus] = param_softplus(cur_y,cur_y_sem,amp_vec, [],0); % Fit to the raw data without correction
        x_vec = linspace(min(amp_vec),max(amp_vec),my_reso);
        y_vec = softplus(p, x_vec);
    end

    twof_growth_func.x_vec(1,:,ichan) = x_vec;
    twof_growth_func.y_vec(1,:,ichan) = y_vec;

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
        cur_y = twof_growth_func.mean(ichan,:);
        cur_y_sem = twof_growth_func.sem(ichan,:);

        % Fit linear regression
        keep = ~isnan(cur_y);
        p_lin = polyfit(amp_vec(keep), cur_y(keep), 1);
        x_vec_lin = linspace(min(amp_vec),max(amp_vec),my_reso);
        y_vec_lin = polyval(p_lin, x_vec_lin);

        errorbar(amp_vec,cur_y,cur_y_sem,'o','Color',cur_color,'MarkerFaceColor',cur_color,'LineWidth',2);
        hold on;
        plot(x_vec_lin,y_vec_lin,'-','Color',cur_color,'LineWidth',2);
        xticks(amp_vec)
        xlabel('Stimulus amplitude')
        ylabel('Amplitude (\muV)')
        title(string(ichan))
    end
    sgtitle(sprintf('%d Hz: Simulated Adaptive 2f Growth Functions (Linear)',cur_freq));
    linkaxes
end
