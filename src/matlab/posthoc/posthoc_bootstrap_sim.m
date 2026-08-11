%% posthoc_bootstrap_simulation
% Assign variables
amp_vec = grand_ex_save{1,1}.info.mixed.test_amplitudes;
amp_vec = sort(amp_vec);
stim_type_vec = grand_ex_save{1,1}.info.mixed.stim_name;
stim_type_idx = find(strcmp('ONOFF',stim_type_vec));
my_chans = [2,3,4];
my_chans_name = {'2 mm subcranial', '4 mm subcranial', 'Subcutaneous'};
itvec = [10 100 500 1000 5000 10000];
% itvec = [5000];
trials_in_batch = 10;
max_batches = 130/trials_in_batch; % 130 trials in batches of 10

% Preallocate
bootstrp_sim = NaN(max_batches, 8, length(amp_vec), length(my_chans), length(itvec));
resp_found_data = NaN(length(my_chans),length(amp_vec),length(itvec));
growth_func_mean = NaN(length(my_chans),length(amp_vec));
growth_func_sem = NaN(length(my_chans),length(amp_vec));
growth_func_noise_floor = NaN(length(my_chans),length(amp_vec));
my_dists = zeros(max(itvec),length(amp_vec));
thresh_fit = NaN(length(my_chans),1);
all = [];
ds = [];
bottom_up = [];
top_down = [];

use_sigmoid = 0;
max_resp_frac = 0.01; % fraction of max slope defining "end of lower asymptote"

%% Calculate bootstrap across channel, n_bootstrap iteration
for iit = 1:length(itvec)
    n_bootstrap = itvec(iit);
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            % Get all ON-OFF data
            cur_phase = squeeze(phase_vec(:,1,iamp,stim_type_idx,ichan));
            diff_2f = ON_2f(:,iamp,stim_type_idx,ichan) - OFF_2f(:,iamp,1,ichan);

            % Keep only real data
            keep = ~isnan(cur_phase) & ~isnan(diff_2f);
            cur_phase = cur_phase(keep);
            diff_2f = diff_2f(keep);
            phases = unique(cur_phase);
            idx = 1;
            resp_found = 0;
            used_all_trials = 0;

            % Loop through batches
            for ibatch = 1:max_batches
                % Ensure equal phases are selected
                n_per_phase = (idx+trials_in_batch-1)/length(phases);
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
                cur_noise_floor = median(cur_off(inc_select));

                % Run bootstrap on current batch of data
                [bootstat, lower_CI, upper_CI] = ...
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
                    cur_noise_floor cur_boot_mean cur_boot_std lower_CI];
                bootstrp_sim(ibatch,:,iamp,ichan,iit) = cur_batch_summary;
                idx = idx+trials_in_batch;
            end
        end
    end
end

%% False +/- Identification
[false_pos, false_neg] = calculate_false_rate(amp_vec, itvec, bootstrp_sim, ...
    resp_found_data, 107, 130, my_chans, trials_in_batch);

%% Estimate threshold based on lower CI value and estimate bias
% Fit softplus to lower_CI growth functions and find zero-crossing threshold
% Only look at highest bootstrap iteration data

lower_ci_vec = squeeze(bootstrp_sim(:,8,:,:,end)); % all channels
boot_std_vec = squeeze(bootstrp_sim(:,7,:,:,end));

% All available data
[p, thresh_ci, stable_n] = ...
    fit_low_CI_model(amp_vec, lower_ci_vec, boot_std_vec, ...
    my_chans_name, 'All data',1);

% Save values
all.amp_vec = amp_vec;
all.p = p;
all.thresh_ci = thresh_ci;
all.stable_n = stable_n;

% Decreasing amplitude resolution
orig_res = diff(amp_vec(1:2));
ds_factors = [2 3 5 6];

for istep = 1:length(ds_factors)
    amp_vec_ds = min(amp_vec):(orig_res*ds_factors(istep)):max(amp_vec);

    % Catch instances where the step size doesnt reach max(amp_vec)
    if max(amp_vec_ds) ~= max(amp_vec)
        amp_vec_ds(end) = max(amp_vec);
    end

    cur_idx = find(ismember(amp_vec,amp_vec_ds));
    my_tag = sprintf('Downsample by %d',ds_factors(istep));

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        my_chans_name, my_tag,0);

    % Save values
    ds(istep).amp_vec_ds = amp_vec_ds;
    ds(istep).ds_factor = diff(amp_vec_ds(1:2));
    ds(istep).p = p;
    ds(istep).thresh_ci = thresh_ci;
    ds(istep).stable_n = stable_n;

end

% Delete from bottom up
for iamp = 2:(length(amp_vec)-2) % Start at 2 since we already know what it looks like with all data points included
    amp_vec_ds = amp_vec(iamp:end);

    cur_idx = find(ismember(amp_vec,amp_vec_ds));
    my_tag = sprintf('Bottom-up %d points deleted',iamp);

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        my_chans_name, my_tag,0);

    % Save values
    bottom_up(iamp-1).amp_vec_ds = amp_vec_ds;
    bottom_up(iamp-1).ds_factor = length(amp_vec)-length(amp_vec_ds);
    bottom_up(iamp-1).p = p;
    bottom_up(iamp-1).thresh_ci = thresh_ci;
    bottom_up(iamp-1).stable_n = stable_n;

end

% Delete from top down
for iamp = 1:(length(amp_vec)-3)
    amp_vec_ds = amp_vec(1:end-iamp);

    cur_idx = find(ismember(amp_vec,amp_vec_ds));
    my_tag = sprintf('Top-down %d points deleted',iamp);

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        my_chans_name, my_tag,0);

    % Save values
    top_down(iamp).amp_vec_ds = amp_vec_ds;
    top_down(iamp).ds_factor = length(amp_vec)-length(amp_vec_ds);
    top_down(iamp).p = p;
    top_down(iamp).thresh_ci = thresh_ci;
    top_down(iamp).stable_n = stable_n;

end

% Compare bias
compare_bias(all,ds,bottom_up,top_down,my_chans_name)

%% 2f based growth function
% Generate vector for plotting 2f based growth function
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        cur_idx = resp_found_data(ichan,iamp,end)/trials_in_batch;
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

% Plot mean 2f amplitude /sem across batches and ID when resp_found
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

% Apply Tufte styling
apply_tufte
