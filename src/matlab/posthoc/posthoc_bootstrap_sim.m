%% posthoc_bootstrap_simulation
clearvars -except grand_ex_save meta org_data

% Assign variables
% Metadata
subjid = meta.subjid;
amp_vec = meta.amp_vec;
stim_type_vec = meta.stim_type_vec;
stim_freq = meta.stim_freq;
my_chans = meta.my_chans;
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;
max_trials = meta.ON_OFF_max_trials;

% Organized data
ON_2f        = org_data.ON_2f;
OFF_2f       = org_data.OFF_2f;
OFF_fft_vals = org_data.OFF_fft_vals;
phase_vec    = org_data.phase_vec;

% Function specific vars
stim_type_idx = find(strcmp('ONOFF',stim_type_vec));
itvec = [10 100 500 1000 5000 10000];
% itvec = [5000];
max_batches = max_trials/trials_per_block; % e.g. 130 trials in batches of 10

% Preallocate
bootstrp_sim = NaN(max_batches, 9, length(amp_vec), length(my_chans), length(itvec));
resp_found_data = NaN(length(my_chans),length(amp_vec),length(itvec));
growth_func_mean = NaN(length(my_chans),length(amp_vec));
growth_func_sem = NaN(length(my_chans),length(amp_vec));
growth_func_noise_floor = NaN(length(my_chans),length(amp_vec));
my_dists = zeros(max(itvec),length(amp_vec));
all_data = [];
ds_data = [];
bottom_up = [];
top_down = [];

use_sigmoid = 0;

%% Calculate bootstrap across channel and n bootstrap iteration
for iit = 1:length(itvec)
    n_bootstrap = itvec(iit);
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            % Get all_data ON-OFF data
            cur_phase = squeeze(phase_vec(:,1,iamp,stim_type_idx,ichan));
            diff_2f = ON_2f(:,iamp,stim_type_idx,ichan) - OFF_2f(:,iamp,1,ichan);

            % Keep only real data
            keep = ~isnan(cur_phase) & ~isnan(diff_2f);
            cur_phase = cur_phase(keep);
            diff_2f = diff_2f(keep);
            phases = unique(cur_phase);
            idx = 1;

            % Loop through batches
            for ibatch = 1:max_batches
                % Ensure equal phases are selected
                n_per_phase = (idx+trials_per_block-1)/length(phases);
                inc_select = [];
                for ip = 1:length(phases)
                    phase_idx = find(cur_phase == phases(ip));
                    inc_select = [inc_select; phase_idx(1:n_per_phase)];
                end

                if sum(cur_phase(inc_select)) ~= 0
                    keyboard
                end

                % Get current batch of data
                cur_data = diff_2f(inc_select);
                cur_mean = mean(cur_data,1);
                cur_sem = std(cur_data,[],1)/sqrt(length(cur_data));
                cur_off = OFF_2f(keep,iamp,1,ichan);
                cur_noise_floor = mean(cur_off(inc_select));
                cur_noise_floor_std = std(cur_off(inc_select));

                % Run bootstrap on current batch of data
                [bootstat, lower_CI, ~] = ...
                    calculate_bootstrap(n_bootstrap, cur_data);

                % Calculate distribution metrics
                cur_boot_mean = mean(bootstat);
                cur_boot_std = std(bootstat);

                % Save only channel 2 bootstrap dist for highest
                % n_bootstrap count
                if ichan == 2 && iit == length(itvec)
                    my_dists(:,iamp) = bootstat;
                end

                resp_found = lower_CI > 0;

                % cur_batch_summary
                % idx = N_trials in average
                cur_batch_summary = [length(inc_select) resp_found cur_mean cur_sem ...
                    cur_noise_floor cur_boot_mean cur_boot_std lower_CI cur_noise_floor_std];
                bootstrp_sim(ibatch,:,iamp,ichan,iit) = cur_batch_summary;
                idx = idx+trials_per_block;
            end
        end
    end
end

%% False +/- Identification
 [false_pos, false_neg, resp_found_data] = calculate_false_rate(amp_vec, itvec, bootstrp_sim, ...
    resp_found_data, 107, max_trials, my_chans, trials_per_block);

%% Estimate threshold based on lower CI value and estimate bias
% Fit softplus to lower_CI growth functions and find zero-crossing threshold
% Only look at highest bootstrap iteration data

% Load in data
lower_ci_vec = squeeze(bootstrp_sim(:,8,:,:,end)); % all_data channels
boot_std_vec = squeeze(bootstrp_sim(:,7,:,:,end));

% all_data available data
[p, thresh_ci, stable_n] = ...
    fit_low_CI_model(amp_vec, lower_ci_vec, boot_std_vec, ...
    trials_per_block, max_trials, my_chans_name, 'all_data data',1);

% Save values
all_data.amp_vec = amp_vec;
all_data.p = p;
all_data.thresh_ci = thresh_ci;
all_data.stable_n = stable_n;

% Decreasing amplitude resolution
orig_res = diff(amp_vec(1:2));
ds_factors = [2 3 5 6];

for istep = 1:length(ds_factors)
    % Downsample amplitude vector
    cur_idx = 1:ds_factors(istep):length(amp_vec);
    cur_idx(end) = length(amp_vec);
    amp_vec_ds = amp_vec(cur_idx);

    % Generate bias ID tag
    my_tag = sprintf('Downsample by %d',ds_factors(istep));

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        trials_per_block, max_trials, my_chans_name, my_tag,1);

    % Save values
    ds_data(istep).amp_vec_ds = amp_vec_ds;
    ds_data(istep).ds_factor = diff(amp_vec_ds(1:2));
    ds_data(istep).p = p;
    ds_data(istep).thresh_ci = thresh_ci;
    ds_data(istep).stable_n = stable_n;

end

% Delete from bottom up
for iamp = 2:(length(amp_vec)-2) % Start at 2 since we already know what it looks like with all_data data points included
    % Remove data points
    amp_vec_ds = amp_vec(iamp:end);
    cur_idx = find(ismember(amp_vec,amp_vec_ds));
    n_points_deleted = length(amp_vec)-length(amp_vec_ds);
    
    % Generate bias ID tag
    my_tag = sprintf('Bottom-up %d points deleted',n_points_deleted);

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        trials_per_block, max_trials,my_chans_name, my_tag,0);

    % Save values
    bottom_up(iamp-1).amp_vec_ds = amp_vec_ds;
    bottom_up(iamp-1).ds_factor = n_points_deleted;
    bottom_up(iamp-1).p = p;
    bottom_up(iamp-1).thresh_ci = thresh_ci;
    bottom_up(iamp-1).stable_n = stable_n;

end

% Delete from top down
for iamp = 1:(length(amp_vec)-3)
    
    % Delete data points
    amp_vec_ds = amp_vec(1:end-iamp);
    cur_idx = find(ismember(amp_vec,amp_vec_ds));
    n_points_deleted = length(amp_vec)-length(amp_vec_ds);
    
    % Generate bias ID tag
    my_tag = sprintf('Top-down %d points deleted',n_points_deleted);

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        trials_per_block, max_trials,my_chans_name, my_tag,0);

    % Save values
    top_down(iamp).amp_vec_ds = amp_vec_ds;
    top_down(iamp).ds_factor = n_points_deleted;
    top_down(iamp).p = p;
    top_down(iamp).thresh_ci = thresh_ci;
    top_down(iamp).stable_n = stable_n;

end

%% Compare bias
compare_bias(all_data,ds_data,bottom_up,top_down,my_chans_name,trials_per_block)

%% 2f based growth function
% Generate vector for plotting 2f based growth function
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        cur_idx = resp_found_data(ichan,iamp,end)/trials_per_block;
        if isnan(cur_idx) % Get the mean and sem of the last measured batch
            growth_func_mean(ichan,iamp) = bootstrp_sim(end,3,iamp,ichan,end);
            growth_func_sem(ichan,iamp) = bootstrp_sim(end,4,iamp,ichan,end);
            growth_func_noise_floor(ichan,iamp) = bootstrp_sim(end,5,iamp,ichan,end);
        else % Get the valid resp_found idx and extract its mean/sem
            growth_func_mean(ichan,iamp) = bootstrp_sim(cur_idx,3,iamp,ichan,end);
            growth_func_sem(ichan,iamp) = bootstrp_sim(cur_idx,4,iamp,ichan,end);
            growth_func_noise_floor(ichan,iamp) = bootstrp_sim(cur_idx,5,iamp,ichan,end);
        end
    end
end

%% SNR based threshold estimation
% get the noise floor amplitude
n_chan = length(my_chans);
cur_amp = 7;
figure; tiledlayout(2,n_chan,'Padding','tight','TileSpacing','tight');
for ichan = 1:n_chan
    chan_color = select_chan_color(ichan);
    cur_mean       = bootstrp_sim(:,3,cur_amp,ichan,end);
    cur_noise_mean = bootstrp_sim(:,5,cur_amp,ichan,end);
    cur_noise_std  = bootstrp_sim(:,9,cur_amp,ichan,end);
    nbatch = 1:10:length(cur_mean)*10;
    threshold_criteria = cur_noise_mean + 5*cur_noise_std;

    % Top row: noise floor amplitude +/- std
    ax_top(ichan) = nexttile(ichan);
    plot(nbatch,cur_noise_std,'-o','Color',chan_color,'MarkerFaceColor',chan_color)
    title(my_chans_name{ichan})
    if ichan == 1, ylabel('Noise floor (\muV)'), end
    xlim([-5 130])
    % Bottom row: 2f mean, colored by SNR criterion
    if cur_mean(end) > threshold_criteria(end)
        snr_color = tableau_10('green');
    else
        snr_color = tableau_10('red');
    end
    ax_bot(ichan) = nexttile(n_chan+ichan);
    plot(nbatch,cur_mean,'-o','Color',snr_color,'MarkerFaceColor',snr_color)
    hold on; plot(nbatch,threshold_criteria,'--','Color',[.5 .5 .5],'LineWidth',2)
    xlabel('Trials in average')
    if ichan == 1, ylabel('2f amplitude (\muV)'), end
    xlim([-5 130])
end
linkaxes([ax_top ax_bot],'x'); linkaxes(ax_top,'y'); linkaxes(ax_bot,'y');
sgtitle('How 2f and noise floor amplitude change as more trials are added to the average')

%% Plot mean 2f amplitude /sem across batches and ID when resp_found
for ichan = 1:length(my_chans)
    figure;
    tiledlayout(4,4,'Padding','tight','TileSpacing','tight');
    for iamp = 1:length(amp_vec)
        nexttile; hold on;

        chan_amp_data = bootstrp_sim(:,:,iamp,ichan,end);
        chan_amp_data = chan_amp_data(~isnan(chan_amp_data(:,1)),:);  % keep filled batches
        batch_num  = chan_amp_data(:,1);
        resp_found = chan_amp_data(:,2);
        batch_mean = chan_amp_data(:,3);
        batch_sem  = chan_amp_data(:,4);

        % Sort batch data
        [batch_num, si] = sort(batch_num);
        batch_mean = batch_mean(si);
        batch_sem  = batch_sem(si);
        resp_found = resp_found(si);

        % Create error fill
        x_vec  = batch_num(:).';
        lo = (batch_mean - batch_sem).';
        hi = (batch_mean + batch_sem).';
        fill([x_vec fliplr(x_vec)], [lo fliplr(hi)], [.7 .7 .7], ...
            'FaceAlpha',.25,'EdgeColor','none','HandleVisibility','off');
        plot(x_vec, batch_mean, 'Color',[.7 .7 .7],'HandleVisibility','off');

        % Plot raw data
        scatter(batch_num(resp_found==1),batch_mean(resp_found==1),40,tableau_10('green'),'filled');
        scatter(batch_num(resp_found==0),batch_mean(resp_found==0),40,tableau_10('red'),'filled');
        title(sprintf('%d dB',amp_vec(iamp)));
        xlabel('N trials in average'); ylabel('Amplitude (\muV)');
    end
    sgtitle(sprintf('Channel %d', my_chans(ichan)));
    hold off;
end

% Plot 2f based growth functions
figure; tiledlayout(1,3,'Padding','tight','TileSpacing','tight');
for ichan = 1:length(my_chans)
    nexttile
    cur_color = select_chan_color(ichan);
    cur_y = growth_func_mean(ichan,:);
    cur_y_sem = growth_func_sem(ichan,:);
    cur_noise_floor = median(growth_func_noise_floor(ichan,:));

    % Fit model
    if use_sigmoid
        % Fit sigmoid
        [p, cur_data, cur_data_sem, logistic] = param_logistic(cur_y, [], amp_vec, []);
        x_vec = linspace(min(amp_vec),max(amp_vec),200);
        y_vec = logistic(p, x_vec);
    else
        % Fit softplus
        [p, cur_data, cur_data_sem, softplus] = param_softplus(cur_y,[],amp_vec, [],0); % Fit to the raw data without correction
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
    title(string(ichan))
end
sgtitle('Simulated Adaptive 2f Growth Functions')

% Plot 2f based growth functions - linear fit
figure; tiledlayout(1,3,'Padding','tight','TileSpacing','tight');
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
sgtitle('Simulated Adaptive 2f Growth Functions (Linear Fit)')


% Apply Tufte styling
apply_tufte
