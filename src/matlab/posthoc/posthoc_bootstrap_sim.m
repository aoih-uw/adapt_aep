%% posthoc_bootstrap_simulation
clearvars -except grand_ex_save meta org_data

% Assign variables
% Metadata
subjid = meta.subjid;
amp_vecs = meta.amp_vecs;
stim_type_vec = meta.stim_type_vec;
if isfield(meta, 'stim_freqs')
    stim_freqs = meta.stim_freqs;
else
    stim_freqs = meta.stim_freq;
end
my_chans = meta.my_chans;
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;
max_trials = meta.ON_OFF_max_trials;
% max_trials = 240;

% Organized data
ON_2f        = org_data.ON_2f;
OFF_2f       = org_data.OFF_2f;
OFF_fft_vals = org_data.OFF_fft_vals;
phase_vec    = org_data.phase_vec;

% Function specific vars
stim_type_idx = find(strcmp('ONOFF',stim_type_vec));
itvec = [5000];
CI_vec = [99.9];
% itvec = [5000];
max_batches = max_trials/trials_per_block; % e.g. 130 trials in batches of 10

% Loop through first by frequency
for ifreq = 1:length(stim_freqs)
    amp_vec = amp_vecs{ifreq};
    % Preallocate matrices
    % Cumulative trial averaging matrix
    sz = [max_batches, length(amp_vec), length(my_chans)];
    cumu.n                    = NaN(sz);
    cumu.diff_mean            = NaN(sz);
    cumu.noise_floor_mean     = NaN(sz);
    
    % Iterations
    sz = [max_batches, length(amp_vec), length(my_chans), length(itvec)];
    iter.boot_mean            = NaN(sz);
    iter.boot_std             = NaN(sz);
    iter.lower_ci             = NaN(sz);
    iter.resp_found           = NaN(sz);

    % CI
    sz = [max_batches, length(amp_vec), length(my_chans), length(CI_vec)];
    conf.boot_mean            = NaN(sz);
    conf.boot_std             = NaN(sz);
    conf.lower_ci             = NaN(sz);
    conf.resp_found           = NaN(sz);

    % Resp found vectors
    resp_found_int = NaN(length(my_chans),length(amp_vec),length(itvec));
    resp_found_conf = NaN(length(my_chans),length(amp_vec),length(CI_vec));

    % 2f Growth function vectors
    growth_func_mean = NaN(length(my_chans),length(amp_vec));
    growth_func_sem = NaN(length(my_chans),length(amp_vec));
    growth_func_noise_floor = NaN(length(my_chans),length(amp_vec));

    % Set to empty
    all_data = [];
    ds_data = [];
    bottom_up = [];
    top_down = [];

    use_sigmoid = 0;

    %% Calculate bootstrap across channel and n bootstrap iteration
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            % Get all_data ON-OFF data
            cur_phase = squeeze(phase_vec(:,1,iamp,stim_type_idx,ichan,ifreq));
            cur_ON = ON_2f(:,iamp,stim_type_idx,ichan,ifreq);
            cur_OFF = OFF_2f(:,iamp,1,ichan,ifreq);

            % Keep only real data
            keep = ~isnan(cur_phase) & ~isnan(cur_ON) & ~isnan(cur_OFF);
            cur_phase = cur_phase(keep);
            cur_ON = cur_ON(keep);
            cur_OFF = cur_OFF(keep);
            phases = unique(cur_phase);
            if size(cur_ON,1) < 260
                fprintf('Not enough trials at %d dB and Channel %d\n', amp_vec(iamp), my_chans(ichan));
            end

            % Set cumulative averaging idx
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

                % Calculate the mean across current cumulative batch of data
                % Difference
                cur_ON = cur_ON(keep);
                cur_OFF = cur_OFF(keep);
                cur_mean = abs(mean(cur_ON,1)); % Take abs to recover magnitude
                
                % Stim off @ 2f
                cur_OFF_2f= OFF_2f(keep,iamp,1,ichan,ifreq);
                cur_noise_floor_mean = mean(cur_OFF_2f(inc_select));

                % Save to cumu
                cumu.n(ibatch,iamp,ichan)                    = length(inc_select);
                cumu.diff_mean(ibatch,iamp,ichan)            = cur_mean;
                cumu.noise_floor_mean(ibatch,iamp,ichan)     = cur_noise_floor_mean;

                % Loop through N iterations
                for iit = 1:length(itvec)
                    n_bootstrap = itvec(iit);
                   
                    % Simulate bootstrap
                    [cur_boot_mean, cur_boot_std, resp_found,lower_CI] = ...
                        simulate_bootstrap(n_bootstrap,cur_ON,cur_OFF,max(CI_vec));

                    % cur_batch_summary
                    % idx = N_trials in average
                    iter.boot_mean(ibatch,iamp,ichan,iit)            = cur_boot_mean;
                    iter.boot_std(ibatch,iamp,ichan,iit)             = cur_boot_std;
                    iter.lower_ci(ibatch,iamp,ichan,iit)             = lower_CI;
                    iter.resp_found(ibatch,iamp,ichan,iit)           = resp_found;
                    
                end

                % Loop through CI intervals
                for iCI =  1:length(CI_vec)
                    % n_bootstrap = max(itvec);
                    % cur_CI = CI_vec(iCI);
                    % 
                    % % Simulate bootstrap
                    % [cur_boot_mean, cur_boot_std, resp_found,lower_CI] = ...
                    %     simulate_bootstrap(n_bootstrap,cur_data,max(CI_vec));
                    % 
                    % % cur_batch_summary
                    % conf.boot_mean(ibatch,iamp,ichan,iCI)            = cur_boot_mean;
                    % conf.boot_std(ibatch,iamp,ichan,iCI)             = cur_boot_std;
                    % conf.lower_ci(ibatch,iamp,ichan,iCI)             = lower_CI;
                    % conf.resp_found(ibatch,iamp,ichan,iCI)           = resp_found;
                end
                % Progress cumulative counter
            idx = idx+trials_per_block;
            end
        end
    end

    %% Simulate trial count
    % By n iteration
    resp_found_int = sim_trial_count_heatmap(amp_vec, iter, ...
        resp_found_int, max_trials, my_chans, trials_per_block);
    % By CI interval
    resp_found_conf = sim_trial_count_heatmap(amp_vec, conf, ...
        resp_found_conf, max_trials, my_chans, trials_per_block);

    %% Estimate threshold based on lower CI value and estimate bias
    % Fit softplus to lower_CI growth functions and find zero-crossing threshold
    % Only look at highest bootstrap iteration data

    % By n iteration
    lower_ci_vec = conf.lower_ci(:,:,:,end); % use highest CI rate
    boot_std_vec = conf.boot_std(:,:,:,end);

    [all_data, ds_data, bottom_up, top_down] = ...
    plan_fit_low_CI(amp_vec, lower_ci_vec, boot_std_vec, trials_per_block, max_trials, my_chans_name);

    % Compare bias
    compare_bias(all_data,ds_data,bottom_up,top_down,my_chans_name,trials_per_block)

    %% 2f based growth function
    % Generate vector for plotting 2f based growth function
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans)
            cur_idx = resp_found_data(ichan,iamp,end)/trials_per_block;
            if isnan(cur_idx) % Get the mean and sem of the last measured batch
                growth_func_mean(ichan,iamp) = cumu.diff_mean(end,iamp,ichan);
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
end

% Apply Tufte styling
apply_tufte
