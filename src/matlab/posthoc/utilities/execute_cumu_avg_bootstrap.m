function [cumu, polar] = execute_cumu_avg_bootstrap(my_params, cumu)
%% Simulate cumulative averaging and bootstrap algorithm
% Assign vars
my_chans = my_params.my_chans;  my_chans_name = my_params.my_chans_name; amp_vec = my_params.amp_vec;
phase_vec = my_params.phase_vec;  ON_2f = my_params.ON_2f;  OFF_2f = my_params.OFF_2f;
stim_type_idx = my_params.stim_type_idx;  ifreq = my_params.ifreq;
cur_freq = my_params.cur_freq;
max_batches = my_params.max_batches;  trials_per_block = my_params.trials_per_block;

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
        cur_phase = squeeze(phase_vec(:,1,iamp,stim_type_idx,ichan,ifreq));
        cur_ON = ON_2f(:,iamp,stim_type_idx,ichan,ifreq);
        cur_OFF = OFF_2f(:,iamp,1,ichan,ifreq);

        % Keep only real data
        keep = ~isnan(cur_phase) & ~isnan(cur_ON) & ~isnan(cur_OFF);
        cur_phase = cur_phase(keep);
        cur_ON = cur_ON(keep);
        cur_OFF = cur_OFF(keep);

        % Plot phase component
        polarscatter(angle(cur_ON), abs(cur_ON), 10, tableau_10('blue'),"filled","MarkerFaceAlpha", 0.3);
        hold on;
        polarscatter(angle(cur_OFF), abs(cur_OFF), 10,tableau_10('orange'),"filled","MarkerFaceAlpha", 0.3);
        title(string(amp_vec(iamp)))

        % Get polar information
        polar.ON = calc_mean_polar(cur_ON,iamp,ichan,polar.ON);
        polar.OFF = calc_mean_polar(cur_OFF,iamp,ichan,polar.OFF);

        % GIF
        if do_gif
            cla(pax); hold(pax,'on');
            polarscatter(pax, angle(cur_ON), abs(cur_ON), 10);
            polarscatter(pax, angle(cur_OFF), abs(cur_OFF), 10);
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
        phases = unique(cur_phase);

        % Identify that we have enough trials
        if size(cur_ON,1) < max_batches*trials_per_block
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
                % inc_select contains idx of of equal phases
                inc_select = [inc_select; phase_idx(1:n_per_phase)];
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
            cumu.n(ibatch,iamp,ichan)                       = length(inc_select);
            cumu.diff.mean.twof(ibatch,iamp,ichan)          = cur_diff_mean; % current batch of stim off (vector)
            cumu.diff.sem.twof(ibatch,iamp,ichan)             = cur_diff_sem;
            cumu.noise_floor.mean.twof(ibatch,iamp,ichan)   = cur_noise_floor_mean; % stim OFF just at 2f
            cumu.noise_floor.sem.twof(ibatch,iamp,ichan)    = cur_noise_floor_sem; % Will figure equation out later

            % F Stats
            % output = [F p];
            cumu.F_stats(ibatch,:,iamp,ichan) = calc_F_stat_2samp(cur_ON_batch,cur_OFF_batch);
            
            % Progress cumulative counter
            idx = idx+trials_per_block;
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
mystruct.PLV(iamp,ichan) = abs(mean(vals./abs(vals))); % I am not familiar with this equation
end