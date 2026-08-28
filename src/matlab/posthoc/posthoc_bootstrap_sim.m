%% posthoc_bootstrap_simulation
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
use_sigmoid = 0;
plot_linear = 0;
% max_trials = 240;

% Organized data
ON_2f        = org_data.ON_2f;
OFF_2f       = org_data.OFF_2f;
OFF_fft_vals = org_data.OFF_fft_vals;
phase_vec    = org_data.phase_vec;

% Function specific vars
stim_type_idx = find(strcmp('ONOFF',stim_type_vec));
itvec = [100 1000 5000];
CI_vec = [90 95 99];
% itvec = [5000];
max_batches = max_trials/trials_per_block; % e.g. 130 trials in batches of 10

% Loop through first by frequency
for ifreq = 1:length(stim_freqs)
    tic()
    % Assign current frequency amp_vec
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

    % Bootstrap decision tracking vectors
    resp_found_vec = NaN(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));

    % 2f Growth function vectors
    growth_func_mean = NaN(length(my_chans),length(amp_vec));
    growth_func_sem = NaN(length(my_chans),length(amp_vec));
    growth_func_noise_floor = NaN(length(my_chans),length(amp_vec));

    % Set to empty
    all_data = []; ds_data = []; bottom_up = []; top_down = [];

    % Package my_params
    my_params.my_chans         = my_chans;
    my_params.my_chans_name    = my_chans_name;
    my_params.amp_vec          = amp_vec;
    my_params.phase_vec        = phase_vec;
    my_params.ON_2f            = ON_2f;
    my_params.OFF_2f           = OFF_2f;
    my_params.stim_type_idx    = stim_type_idx;
    my_params.ifreq            = ifreq;
    my_params.cur_freq          = stim_freqs(ifreq);
    my_params.max_batches      = max_batches;
    my_params.trials_per_block = trials_per_block;
    my_params.itvec            = itvec;
    my_params.CI_vec           = CI_vec;

    %% Execute cumulative averaging/bootstrapping simulation
    tic()
    [cumu, simu] = execute_cumu_avg_bootstrap(my_params, cumu, simu);
    toc()

    %% Plot 2f and noise floor amplitude across batches
    c = parula(max_trials/trials_per_block);
    figure; tiledlayout(2,length(my_chans),"TileSpacing",'tight','Padding','tight')
    n = max_trials/trials_per_block;
    for ichan = 1:length(my_chans)
        nexttile(ichan); hold on;
        title(my_chans_name{ichan});
        if ichan == 1, ylabel('2f Magnitude (\muV)'); end
        for i = 1:n
            plot(amp_vec,cumu.diff_mean_2f(i,:,ichan),'Color',c(i,:));
        end
        nexttile(ichan+length(my_chans)); hold on;
        if ichan == 1, ylabel('Noise Floor at 2f bin (\muV)'); end
        for i = 1:n
            plot(amp_vec,cumu.noise_floor_mean_2f(i,:,ichan),'Color',c(i,:));
        end
    end
    colormap(parula);

    %% Simulate adaptive trial count
    % By n iteration
    resp_found_vec = sim_trial_count_heatmap(amp_vec, simu,...
        resp_found_vec, max_trials, my_chans, my_chans_name, trials_per_block, itvec, CI_vec,my_params);

    %% Plot 2f growth functions
    [growth_func_mean, growth_func_sem, growth_func_noise_floor] = ...
        plot_2f_growth_func(cumu, resp_found_vec, amp_vec, my_chans, my_chans_name, ...
        trials_per_block, stim_freqs(ifreq), use_sigmoid,plot_linear);

    %% Plot mean 2f amplitude across batches and ID when resp_found
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
        sgtitle(sprintf('%d Hz; Channel %d', stim_freqs(ifreq), my_chans(ichan)));
        hold off;
    end

    %% Estimate threshold based on lower CI value and estimate bias
    % Fit softplus to lower_CI growth functions and find zero-crossing threshold
    % Only look at highest bootstrap iteration data

    % By n iteration
    lower_ci_vec = simu.lower_ci(:,:,:,end,end); % use highest CI rate and n_bootstrap
    boot_sem_vec = simu.boot_sem(:,:,:,end,end);

    [all_data] = ...
        plan_fit_low_CI(amp_vec, lower_ci_vec, boot_sem_vec, trials_per_block, max_trials, my_chans_name, my_params, resp_found_vec);

    %% REVIST ANOTHER TIME
    % Revisit bias calculation another time
    % compare_bias(all_data,ds_data,bottom_up,top_down,my_chans_name,trials_per_block)

    %% SNR based threshold estimation
    % % get the noise floor amplitude
    % n_chan = length(my_chans);
    % cur_amp = 10;
    % my_std = 3;
    % figure; tiledlayout(2,n_chan,'Padding','tight','TileSpacing','tight');
    % for ichan = 1:n_chan
    %     chan_color = select_chan_color(ichan);
    %     cur_mean       = cumu.diff_mean_2f(:,cur_amp,ichan,end,end);
    %     cur_noise_mean = cumu.noise_floor_mean_2f(:,cur_amp,ichan,end,end);
    %     cur_noise_sem  = cumu.noise_floor_sem_2f(:,cur_amp,ichan,end,end);
    %     nbatch = 1:10:length(cur_mean)*10;
    %     threshold_criteria = cur_noise_mean + my_std*cur_noise_sem;
    %
    %     % Top row: noise floor amplitude +/- std
    %     ax_top(ichan) = nexttile(ichan);
    %     errorbar(nbatch,cur_noise_mean,cur_noise_sem,'-o','Color',chan_color,'MarkerFaceColor',chan_color)
    %     title(my_chans_name{ichan})
    %     if ichan == 1, ylabel('Noise floor mean (\muV)'), end
    %     % Bottom row: 2f mean, colored by SNR criterion
    %     if cur_mean(end) > threshold_criteria(end)
    %         snr_color = tableau_10('green');
    %     else
    %         snr_color = tableau_10('red');
    %     end
    %     ax_bot(ichan) = nexttile(n_chan+ichan);
    %     plot(nbatch,cur_mean,'-o','Color',snr_color,'MarkerFaceColor',snr_color)
    %     hold on; plot(nbatch,threshold_criteria,'--','Color',[.5 .5 .5],'LineWidth',2)
    %     xlabel('Trials in average')
    %     if ichan == 1, ylabel('2f amplitude (\muV)'), end
    % end
    % sgtitle(sprintf('%d Hz @ %d dB: SNR based threshold %d STD ',stim_freqs(ifreq), cur_amp,my_std));

    fprintf('%d Hz',stim_freqs(ifreq))
    toc()
end

