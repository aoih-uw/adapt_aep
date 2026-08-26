function [cumu, simu] = execute_cumu_avg_bootstrap(my_params, cumu, simu)
%% Simulate cumulative averaging and bootstrap algorithm
% Assign vars
my_chans = my_params.my_chans;  my_chans_name = my_params.my_chans_name; amp_vec = my_params.amp_vec;
phase_vec = my_params.phase_vec;  ON_2f = my_params.ON_2f;  OFF_2f = my_params.OFF_2f;
stim_type_idx = my_params.stim_type_idx;  ifreq = my_params.ifreq;
cur_freq = my_params.cur_freq;
max_batches = my_params.max_batches;  trials_per_block = my_params.trials_per_block;
itvec = my_params.itvec;  CI_vec = my_params.CI_vec;
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
            cur_diff_mean = abs(mean(cur_ON_batch)) - abs(mean(cur_OFF_batch)); % Mean diff for current cumulative batch of trial
            cur_diff_sem = (abs(std(cur_ON_batch - cur_OFF_batch)))/sqrt(length(cur_ON_batch));
            
            % Stim off @ 2f
            cur_noise_floor_mean = abs(mean(cur_OFF_batch));
            cur_noise_floor_sem = (abs(std(cur_OFF_batch)))/sqrt(length(cur_OFF_batch));

            % Save to cumu
            cumu.n(ibatch,iamp,ichan)                    = length(inc_select);
            cumu.diff_mean_2f(ibatch,iamp,ichan)            = cur_diff_mean; % current batch of stim off (vector)
            cumu.diff_sem_2f(ibatch,iamp,ichan)             = 0;
            cumu.noise_floor_mean_2f(ibatch,iamp,ichan)     = cur_noise_floor_mean; % stim OFF just at 2f
            cumu.noise_floor_sem_2f(ibatch,iamp,ichan)         = cur_noise_floor_sem; % Will figure equation out later

            % Loop through N bootstrap iterations (all CI levels share one run)
            for iit = 1:length(itvec)
                n_bootstrap = itvec(iit);

                [bootstat, lower_CI_all] = ...
                    calculate_bootstrap(n_bootstrap, cur_ON_batch, cur_OFF_batch, CI_vec);

                simu.boot_mean(ibatch,iamp,ichan,iit,:) = mean(bootstat);
                simu.boot_sem(ibatch,iamp,ichan,iit,:)  = std(bootstat);
                simu.lower_ci(ibatch,iamp,ichan,iit,:)  = lower_CI_all;
                simu.resp_found(ibatch,iamp,ichan,iit,:) = lower_CI_all > 0;
            end
            % Progress cumulative counter
            idx = idx+trials_per_block;
        end
    end
    sgtitle(sprintf('Channel: %s; Frequency: %d Hz',my_chans_name{ichan}, cur_freq))
end