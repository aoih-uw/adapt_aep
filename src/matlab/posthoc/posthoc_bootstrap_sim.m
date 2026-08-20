%% posthoc_bootstrap_simulation
clearvars -except grand_ex_save meta org_data

%% Assign variables
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
itvec = [2500];
CI_vec = [99];
% itvec = [5000];
max_batches = max_trials/trials_per_block; % e.g. 130 trials in batches of 10

% Loop through first by frequency
for ifreq = 1:length(stim_freqs)
    amp_vec = amp_vecs{ifreq};
    %% Preallocate matrices
    % Cumulative trial averaging matrix
    sz = [max_batches, length(amp_vec), length(my_chans)];
    cumu.n                       = NaN(sz);
    cumu.diff_mean_2f            = NaN(sz);
    cumu.diff_sem_2f             =  NaN(sz);
    cumu.noise_floor_mean_2f     = NaN(sz);
    cumu.noise_floor_sem_2f      =  NaN(sz);

    % Simulation
    sz = [max_batches, length(amp_vec), length(my_chans), length(itvec), length(CI_vec)];
    simu.boot_mean            = NaN(sz);
    simu.boot_sem             = NaN(sz);
    simu.lower_ci             = NaN(sz);
    simu.resp_found           = NaN(sz);

    % Resp found vectors
    resp_found_vec = NaN(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));

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

    %% Simulate cumulative averaging and bootstrap algorithm
    for ichan = 1:length(my_chans)
        figure;tiledlayout(4,4,'TileSpacing','tight','Padding','tight')
        for iamp = 1:length(amp_vec)
            nexttile
            % Get all_data ON-OFF data
            cur_phase = squeeze(phase_vec(:,1,iamp,stim_type_idx,ichan,ifreq));
            cur_ON = ON_2f(:,iamp,stim_type_idx,ichan,ifreq);
            cur_OFF = OFF_2f(:,iamp,1,ichan,ifreq);

            % Keep only real data
            keep = ~isnan(cur_phase) & ~isnan(cur_ON) & ~isnan(cur_OFF);
            cur_phase = cur_phase(keep);

            % cur_ON / OFF for all batches but for current channel and
            % amplitude
            cur_ON = cur_ON(keep);
            cur_OFF = cur_OFF(keep);

            % Plot phase component
            polarscatter(angle(cur_ON), abs(cur_ON), 10);
            hold on;
            polarscatter(angle(cur_OFF), abs(cur_OFF), 10);
            title(string(amp_vec(iamp)))

            % Identify unique phases
            phases = unique(cur_phase);

            % See if we have enough trials
            if size(cur_ON,1) < 260
                fprintf('Not enough trials at %d dB and Channel %d\n', amp_vec(iamp), my_chans(ichan));
            end

            % Set cumulative averaging idx
            idx = 1;

            % Loop through batches cumulatively
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
                n_batch = length(inc_select);
                cur_ON_batch = cur_ON(inc_select); % Complex vector of ON fft vals for current cumulative batch
                cur_OFF_batch = cur_OFF(inc_select); % Complex vector of OFF fft vals for current cumulative batch
                cur_diff_mean = abs(mean(cur_ON_batch)) - abs(mean(cur_OFF_batch)); % Mean diff for current cumulative batch of trials
                cur_diff_sem = (abs(std(cur_ON_batch)) - abs(std(cur_OFF_batch)))/sqrt(n_batch);

                % Stim off @ 2f
                cur_noise_floor_mean = abs(mean(cur_OFF_batch));
                cur_noise_floor_sem = abs(std(cur_OFF_batch));

                % Save to cumu
                cumu.n(ibatch,iamp,ichan)                    = length(inc_select);
                cumu.diff_mean_2f(ibatch,iamp,ichan)            = cur_diff_mean; % current batch of stim off (vector)
                cumu.diff_sem_2f(ibatch,iamp,ichan)             = cur_diff_sem;
                cumu.noise_floor_mean_2f(ibatch,iamp,ichan)     = cur_noise_floor_mean; % stim OFF just at 2f
                cumu.noise_floor_sem_2f(ibatch,iamp,ichan)         = cur_noise_floor_sem;

                % Loop through N iterations
                for iit = 1:length(itvec)
                    for iCI = 1:length(CI_vec)
                        % Select current parameters
                        n_bootstrap = itvec(iit);
                        cur_CI = CI_vec(iCI);

                        % Simulate bootstrap
                        [cur_boot_mean, cur_boot_sem, resp_found,lower_CI] = ...
                            simulate_bootstrap(n_bootstrap,cur_ON,cur_OFF,cur_CI);

                        % cur_batch_summary
                        % idx = N_trials in average
                        simu.boot_mean(ibatch,iamp,ichan,iit,iCI)            = cur_boot_mean;
                        simu.boot_sem(ibatch,iamp,ichan,iit,iCI)             = cur_boot_sem;
                        simu.lower_ci(ibatch,iamp,ichan,iit,iCI)             = lower_CI;
                        simu.resp_found(ibatch,iamp,ichan,iit,iCI)           = resp_found;
                    end
                end
                % Progress cumulative counter
                idx = idx+trials_per_block;
            end
        end
    end

    %% Simulate adaptive trial count
    % By n iteration
    resp_found_vec = sim_trial_count_heatmap(amp_vec, simu,...
        resp_found_vec, max_trials, my_chans, trials_per_block);

    %% 2f based growth function (SOFTPLUS)
    % Generate vector for plotting 2f based growth function
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
    sgtitle(sprintf('%d Hz: Simulated Adaptive 2f Growth Functions (Softplus)',stim_freqs(ifreq)));

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
    sgtitle(sprintf('%d Hz: Simulated Adaptive 2f Growth Functions (Linear)',stim_freqs(ifreq)));

    %% Plot mean diff 2f amplitude/sem across batches and ID when resp_found
    for ichan = 1:length(my_chans)
        figure;
        tiledlayout(4,4,'Padding','tight','TileSpacing','tight');
        for iamp = 1:length(amp_vec)
            nexttile; hold on;

            batch_num  = cumu.n(:,iamp,ichan);
            resp_found = simu.resp_found(:,iamp,ichan,end,end); % Use highest iteration and CI numbers
            batch_mean = cumu.diff_mean_2f(:,iamp,ichan);
            batch_sem  = cumu.diff_sem_2f(:,iamp,ichan);

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
        sgtitle(sprintf('%d Hz: Channel %d', stim_freqs(ifreq), my_chans(ichan)));
        hold off;
    end

    %% Estimate threshold based on lower CI value and estimate bias
    % Fit softplus to lower_CI growth functions and find zero-crossing threshold
    % Only look at highest bootstrap iteration data

    % By n iteration
    lower_ci_vec = simu.lower_ci(:,:,:,end,end); % use highest CI rate and n_bootstrap
    boot_sem_vec = simu.boot_sem(:,:,:,end,end);

    [all_data] = ...
        plan_fit_low_CI(amp_vec, lower_ci_vec, boot_sem_vec, trials_per_block, max_trials, my_chans_name);

    %% Revisit bias calculation another time
    % % Compare bias
    % compare_bias(all_data,ds_data,bottom_up,top_down,my_chans_name,trials_per_block)

    %% SNR based threshold estimation
    % get the noise floor amplitude
    n_chan = length(my_chans);
    cur_amp = 10;
    figure; tiledlayout(2,n_chan,'Padding','tight','TileSpacing','tight');
    for ichan = 1:n_chan
        chan_color = select_chan_color(ichan);
        cur_mean       = cumu.diff_mean_2f(:,cur_amp,ichan,end,end);
        cur_noise_mean = cumu.noise_floor_mean_2f(:,cur_amp,ichan,end,end);
        cur_noise_sem  = cumu.noise_floor_sem_2f(:,cur_amp,ichan,end,end);
        nbatch = 1:10:length(cur_mean)*10;
        threshold_criteria = cur_noise_mean + 3*cur_noise_sem;

        % Top row: noise floor amplitude +/- std
        ax_top(ichan) = nexttile(ichan);
        errorbar(nbatch,cur_noise_mean,cur_noise_sem,'-o','Color',chan_color,'MarkerFaceColor',chan_color)
        title(my_chans_name{ichan})
        if ichan == 1, ylabel('Noise floor mean (\muV)'), end
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
    end
    sgtitle(sprintf('%d Hz: SNR based threshold',stim_freqs(ifreq)));

end
%% Apply Tufte styling
apply_tufte
