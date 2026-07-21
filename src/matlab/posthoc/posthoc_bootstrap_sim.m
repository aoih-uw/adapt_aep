%% posthoc_bootstrap_simulation
% Assign variables
amp_vec = 95:3:140;
my_chans = [2,3,4];
n_bootstrap = 5000;
trials_in_batch = 10;
max_batches = 130/trials_in_batch; % 130 trials in batches of 10
bootstrp_sim = NaN(max_batches, 5, length(amp_vec), length(my_chans));
resp_found_data = NaN(length(my_chans),length(amp_vec));
growth_func_mean = NaN(length(my_chans),length(amp_vec));
growth_func_sem = NaN(length(my_chans),length(amp_vec));
growth_func_noise_floor = NaN(length(my_chans),length(amp_vec));

thresh_fit = NaN(length(my_chans));
use_sigmoid = 0;
sp_slope_frac = 0.01; % fraction of max slope defining "end of lower asymptote"


% Loop through data
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        % Get all ON-OFF data
        diff_2f = ON_2f(:,iamp,2,ichan) - OFF_2f(:,iamp,1,ichan);
        diff_2f(isnan(diff_2f)) = [];
        idx = 1;
        resp_found = 0;
        used_all_trials = 0;
        for ibatch = 1:max_batches
            % Get current batch of data
            cur_data = diff_2f(1:(idx+trials_in_batch-1));
            cur_mean = mean(cur_data,1);
            cur_sem = std(cur_data,[],1)/sqrt(length(cur_data));
            cur_noise_floor = median(OFF_2f(1:(idx+trials_in_batch-1),iamp,1,ichan));

            % Run bootstrap on current batch of data
            [bootstat, lower_CI, upper_CI] = ...
                calculate_bootstrap(n_bootstrap, cur_data);

            resp_found = lower_CI > 0;

            % cur_batch_summary
            % idx = N_trials in average
            cur_batch_summary = [(idx+trials_in_batch-1) resp_found cur_mean cur_sem cur_noise_floor];
            bootstrp_sim(ibatch,:,iamp,ichan) = cur_batch_summary;
            idx = idx+trials_in_batch;
        end
    end
end

% For each iamp and ichan find the first *stable* resp_found batch
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        cur_data = bootstrp_sim(:,:,iamp,ichan);
        last_no_resp = find(cur_data(:,2) == 0,1,'last');
        if last_no_resp == 13
            % no response found at any point
            resp_found_data(ichan,iamp) = NaN;
        elseif isempty(last_no_resp) % All batches have found_response, just pick the first one
            resp_found_data(ichan,iamp) = trials_in_batch;
        else % There was a mid batch no response, so find the last no response and take the first yes response right after or not even whent there is a midbatch
            resp_found_data(ichan,iamp) = cur_data(last_no_resp+1,1);
        end
    end
end

% Generate vector for plotting model
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        cur_idx = resp_found_data(ichan,iamp)/trials_in_batch;
        if isnan(cur_idx) % Get the mean and sem of the last measured batch
            growth_func_mean(ichan,iamp) = bootstrp_sim(end,3,iamp,ichan);
            growth_func_sem(ichan,iamp) = bootstrp_sim(end,4,iamp,ichan);
            growth_func_noise_floor(ichan,iamp) = bootstrp_sim(end,5,iamp,ichan);
        else % Get the valid resp_found idx and extract its mean/sem
            growth_func_mean(ichan,iamp) = bootstrp_sim(cur_idx,3,iamp,ichan);
            growth_func_sem(ichan,iamp) = bootstrp_sim(cur_idx,4,iamp,ichan);
            growth_func_noise_floor(ichan,iamp) = bootstrp_sim(cur_idx,5,iamp,ichan);
        end
    end
end

%% Plot
% Plot mean/sem across batches and ID when resp_found
for ichan = 1:length(my_chans)
    figure;
    tiledlayout(1,16,'Padding','tight','TileSpacing','tight');
    for iamp = 1:length(amp_vec)
        nexttile; hold on;
        chan_amp_data = bootstrp_sim(:,:,iamp,ichan);
        chan_amp_data = chan_amp_data(~isnan(chan_amp_data(:,1)),:);  % keep filled batches
        batch_num  = chan_amp_data(:,1);
        resp_found = chan_amp_data(:,2);
        batch_mean = chan_amp_data(:,3);
        batch_sem  = chan_amp_data(:,4);
        errorbar(batch_num,batch_mean,batch_sem,'Color',[.7 .7 .7],'HandleVisibility','off');
        scatter(batch_num(resp_found==1),batch_mean(resp_found==1),40,tableau_10('green'),'filled');
        scatter(batch_num(resp_found==0),batch_mean(resp_found==0),40,tableau_10('red'),'filled');
        title(amp_vec(iamp))
        xlabel('N trials'); ylabel('Mean \pm SEM');
    end
    sgtitle(sprintf('Channel %d', my_chans(ichan)));
    hold off;
end

% Plot min num of trials needed to find reliable resp_found (i.e., no more
% no resp_found after resp_found)
figure
for ichan = 1:length(my_chans)
    if ichan == 1
        cur_color = tableau_10('blue');
    elseif ichan == 2
        cur_color = tableau_10('orange');
    elseif ichan == 3
        cur_color = tableau_10('purple');
    end
    plot(amp_vec,resp_found_data(ichan,:),'-o','Color',cur_color,'MarkerFaceColor',cur_color,'LineWidth',2);
    hold on;
end
ylim([0,50])
xticks(amp_vec)
yticks(0:5:50)
xlim([95 140])
xlabel('Stimulus amplitude')
ylabel('N trials needed for + response')
title('How many trials need to be in the average to find a response?')
legend(string(my_chans))

% Plot growth functions
figure; tiledlayout(1,3,'Padding','tight','TileSpacing','tight');
for ichan = 1:length(my_chans)
    nexttile
    if ichan == 1
        cur_color = tableau_10('blue');
    elseif ichan == 2
        cur_color = tableau_10('orange');
    elseif ichan == 3
        cur_color = tableau_10('purple');
    end
    cur_y = growth_func_mean(ichan,:);
    cur_y_sem = growth_func_sem(ichan,:);
    cur_noise_floor = median(growth_func_noise_floor(ichan,:));

    % Fit model
    if use_sigmoid 
        % Fit sigmoid
        [p, cur_data, cur_data_sem, logistic] = param_logistic(cur_y, [], amp_vec, []);
    else
        % Fit softplus
        [p, cur_data, cur_data_sem, softplus] = param_softplus(cur_y,[],amp_vec, []); % Fit to the raw data without correction
    end

    % Find threshold
    x_vec = linspace(min(amp_vec),max(amp_vec),200);
    if use_sigmoid
        y_vec = logistic(p,x_vec);
    else
        y_vec = softplus(p,x_vec);
    end
    thresh_fit(ichan) = p(3) + (1/p(2))*log(sp_slope_frac/(1-sp_slope_frac));
    
    % Plot raw data
    errorbar(amp_vec,cur_y,cur_y_sem,'-o','Color',cur_color,'MarkerFaceColor',cur_color,'LineWidth',2);
    hold on;
    % Plot fitted curve
    plot(x_vec,y_vec,'-','Color',tableau_10('grey'),'LineWidth',2);
    xline(thresh_fit(ichan))
    xticks(amp_vec)
    xlabel('Stimulus amplitude')
    ylabel('Amplitude (\muV)')
    title(string(ichan))
end
sgtitle('Simulated Adaptive Growth Functions')

% Apply Tufte styling
apply_tufte

% Save figures
figs = findall(0, 'Type', 'figure');
for i = 1:length(figs)
    figs(i).WindowState = 'maximized';
    drawnow;
    exportgraphics(figs(i), sprintf('%d_figure_%d_1024_trials.png', subjid, figs(i).Number), 'Resolution', 300);
    savefig(figs(i), sprintf('%d_figure_%d_bootstrap.fig', subjid, figs(i).Number));
end