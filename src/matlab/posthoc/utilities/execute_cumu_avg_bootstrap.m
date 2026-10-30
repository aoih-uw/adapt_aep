function [cumu, polar] = execute_cumu_avg_bootstrap(my_params, cumu)
%% Simulate cumulative averaging and bootstrap algorithm
% Assign vars
my_chans = my_params.my_chans;  my_chans_name = my_params.my_chans_name; amp_vec = my_params.amp_vec;
phase_vec = my_params.phase_vec;  ON_2f = my_params.ON_2f;  OFF_2f = my_params.OFF_2f;
stim_type_idx = my_params.stim_type_idx;  ifreq = my_params.ifreq;
cur_freq = my_params.cur_freq;
max_batches = my_params.max_batches;  trials_per_block = my_params.trials_per_block;
n_boot = my_params.n_boot;

% Preallocate
sz = [length(amp_vec), length(my_chans)];
for myfields = {'ON', 'OFF'}
    polar.(myfields{1}).n = NaN(sz);
    polar.(myfields{1}).mag.mean   = NaN(sz);
    polar.(myfields{1}).mag.std    = NaN(sz);
    polar.(myfields{1}).angle.mean = NaN(sz);
    polar.(myfields{1}).PLV        = NaN(sz);
end

% Start looping through channels
for ichan = 1:length(my_chans)
    fprintf("Simulating Channel %d\n",ichan)
    figure;
    tl = tiledlayout(4,5,'TileSpacing','tight','Padding','tight');

    % Setup GIF
    % do_gif = contains(my_chans_name{ichan}, 'subcranial', 'IgnoreCase', true);
    do_gif = 0;
    if do_gif
        gif_file = sprintf('polar_%s_%dHz.gif', my_chans_name{ichan}, cur_freq);
        rmax = max(abs([ON_2f(:,:,stim_type_idx,ichan,ifreq); OFF_2f(:,:,1,ichan,ifreq)]),[],'all','omitnan');
        fa = figure('Visible','off'); pax = polaraxes(fa);
    end

    % Loop through amplitudes
    for iamp = 1:length(amp_vec)
        nexttile(tl)

        % Get all_data ON-OFF data
        cur_phase_all = squeeze(phase_vec(:,1,iamp,stim_type_idx,ichan,ifreq));
        cur_ON_all = ON_2f(:,iamp,stim_type_idx,ichan,ifreq);
        cur_OFF_all = OFF_2f(:,iamp,1,ichan,ifreq);

        % Keep only real data
        keep = ~isnan(cur_phase_all) & ~isnan(cur_ON_all) & ~isnan(cur_OFF_all);
        cur_phase_all = cur_phase_all(keep);
        cur_ON_all = cur_ON_all(keep);
        cur_OFF_all = cur_OFF_all(keep);

        % Plot phase component
        polarscatter(angle(cur_ON_all), abs(cur_ON_all), 10, tableau_10('blue'),"filled","MarkerFaceAlpha", 0.3);
        hold on;
        polarscatter(angle(cur_OFF_all), abs(cur_OFF_all), 10,tableau_10('orange'),"filled","MarkerFaceAlpha", 0.3);
        title(string(amp_vec(iamp)))

        % Get polar information
        polar.ON = calc_mean_polar(cur_ON_all,iamp,ichan,polar.ON);
        polar.OFF = calc_mean_polar(cur_OFF_all,iamp,ichan,polar.OFF);

        % GIF
        if do_gif
            cla(pax); hold(pax,'on');
            polarscatter(pax, angle(cur_ON_all), abs(cur_ON_all), 10);
            polarscatter(pax, angle(cur_OFF_all), abs(cur_OFF_all), 10);
            rlim(pax,[0 rmax]); title(pax, sprintf('%d dB', amp_vec(iamp)));
            [A,map] = rgb2ind(frame2im(getframe(fa)), 256);
            dt = 0.2; if iamp == length(amp_vec), dt = 2; end
            if iamp == 1
                imwrite(A, map, gif_file, 'gif', 'LoopCount', Inf, 'DelayTime', dt);
            else
                imwrite(A, map, gif_file, 'gif', 'WriteMode', 'append', 'DelayTime', dt);
            end
        end

        % Identify unique phases
        phases = unique(cur_phase_all);

        % Identify that we have enough trials
        if size(cur_ON_all,1) < max_batches*trials_per_block
            fprintf('Not enough trials at %d dB and Channel %d\n', amp_vec(iamp), my_chans(ichan));
        end

        % Create bootstrapped trial set
        for iboot = 1:n_boot
            % Ensure equal phases are selected
            boot_idx = [];
            if iboot == n_boot 
                % Ensure that last bootstrap doesn't randomize order, to simulate real experiment
                for ip = 1:length(phases)
                    phase_idx = find(cur_phase_all == phases(ip));
                    % inc_select contains idx of of equal phases
                    boot_idx = [boot_idx; phase_idx];
                end
                boot_idx = sort(boot_idx);
            else
                % Randomly select trials we will work with to simulate batch based averaging
                % with replacement by phase 
                for ip = 1:length(phases)
                    phase_idx = find(cur_phase_all == phases(ip));
                    % inc_select contains idx of of equal phases
                    boot_idx = [boot_idx; phase_idx(randi(length(phase_idx),length(phase_idx),1))];
                end
            end

            % Index current set of data
            cur_ON = cur_ON_all(boot_idx);
            cur_OFF = cur_OFF_all(boot_idx);
            cur_phase = cur_phase_all(boot_idx);

            % Set cumulative averaging idx
            idx = 1;

            % Loop through batches cumulatively
            for ibatch = 1:max_batches
             
                % Select balanced phases again after resampling trials
                n_per_phase = (idx+trials_per_block-1)/length(phases);
                inc_select = [];
                for ip = 1:length(phases)
                    phase_idx = find(cur_phase == phases(ip));
                    inc_select = [inc_select; phase_idx(1:n_per_phase)]; % 1:n_per_phase gurantees that we are testing "in trial order"
                end

                % Ensure that even phases are selected for cumulative batches
                if sum(cur_phase(inc_select)) ~= 0
                    fprintf('Uneven phases selected\n')
                end

                % Calculate the mean across current cumulative batch of data
                % Difference
                cur_ON_batch = cur_ON(inc_select); % Complex vector of ON fft vals for current cumulative batch
                cur_OFF_batch = cur_OFF(inc_select); % Complex vector of OFF fft vals for current cumulative batch
                cur_diff_mean = abs(mean(cur_ON_batch)) - abs(mean(cur_OFF_batch)); % Mean diff for current cumulative batch of trial
                cur_diff_sem = (abs(std(cur_ON_batch - cur_OFF_batch)))/sqrt(length(cur_ON_batch));

                % Stim off @ 2f
                cur_noise_floor_mean = abs(mean(cur_OFF_batch));
                cur_noise_floor_sem = (abs(std(cur_OFF_batch)))/sqrt(length(cur_OFF_batch));

                % Save to cumu
                cumu.n(ibatch,iamp,ichan,iboot)                       = length(inc_select);
                cumu.diff.mean.twof(ibatch,iamp,ichan,iboot)          = cur_diff_mean; % current batch of stim off (vector)
                cumu.diff.sem.twof(ibatch,iamp,ichan,iboot)             = cur_diff_sem;
                cumu.noise_floor.mean.twof(ibatch,iamp,ichan,iboot)   = cur_noise_floor_mean; % stim OFF just at 2f
                cumu.noise_floor.sem.twof(ibatch,iamp,ichan,iboot)    = cur_noise_floor_sem; % Will figure equation out later

                % F Stats
                % output = [F p];
                cumu.F_stats(ibatch,:,iamp,ichan,iboot) = calc_F_stat_2samp(cur_ON_batch,cur_OFF_batch);

                % Progress cumulative counter
                idx = idx+trials_per_block;
            end
        end
    end
    if do_gif, close(fa); end
    sgtitle(tl, sprintf('Channel: %s | Frequency: %d Hz', my_chans_name{ichan}, cur_freq))
end
end

function mystruct = calc_mean_polar(vals, iamp,ichan,mystruct)
mystruct.n(iamp,ichan) = numel(vals);
cur_mean = mean(vals);
mystruct.mag.mean(iamp,ichan) = abs(cur_mean);
mystruct.mag.std(iamp,ichan) = std(vals); % Spread of dots
mystruct.angle.mean(iamp,ichan) = angle(cur_mean);
%% Phase locking value 
% gives a value from 0-1 since by dividing by abs(vals)
% all vectors have a length of 1, and then by dividing by N when
% calculating the mean, the highest possible value is 1 (all N arrows with
% magnitude value of 1 point the same way), and lowest 0 (all arrows point randomly in different directions)
mystruct.PLV(iamp,ichan) = abs(mean(vals./abs(vals))); % I am not familiar with this equation
end