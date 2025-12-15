function [FFT_block_avgs, ex] = calculateFFTBlock_runavg(FFT_block_data, ifft, Nchan, channel_names, ex, ifreq, iamp)

prestim_sig = FFT_block_data.prestim_sig;
stimresp_sig = FFT_block_data.stimresp_sig;
poststimresp_sig = FFT_block_data.poststimresp_sig;

FFT_block_avgs = struct();

% Clear variables to prevent size compatibility errors between FFT blocks
clear prev_prestim_avg prev_stimresp_avg prev_poststimresp_avg
clear prev_prestim_sumsq prev_stimresp_sumsq prev_poststimresp_sumsq
clear new_prestim_avg new_stimresp_avg new_poststimresp_avg
clear new_prestim_std new_stimresp_std new_poststimresp_std
clear new_prestim_sumsq new_stimresp_sumsq new_poststimresp_sumsq
clear prestim_mean_diff_sq stimresp_mean_diff_sq poststimresp_mean_diff_sq
clear cur_prestim cur_prestim_avg cur_prestim_sumsq
clear cur_stimresp cur_stimresp_avg cur_stimresp_sumsq
clear cur_poststimresp cur_poststimresp_avg cur_poststimresp_sumsq
clear N_prev N_cur N_total firstfft curchan_name

for ich = 1:Nchan
    curchan_name = channel_names{ich};

    %% Extract new chunk
    cur_prestim = prestim_sig(:,:,ich);
    cur_prestim_avg = mean(cur_prestim, 1);
    cur_prestim_sumsq = sum((cur_prestim - cur_prestim_avg).^2, 1);

    cur_stimresp = stimresp_sig(:,:,ich);
    cur_stimresp_avg = mean(cur_stimresp, 1);
    cur_stimresp_sumsq = sum((cur_stimresp - cur_stimresp_avg).^2, 1);

    cur_poststimresp = poststimresp_sig(:,:,ich);
    cur_poststimresp_avg = mean(cur_poststimresp, 1);
    cur_poststimresp_sumsq = sum((cur_poststimresp - cur_poststimresp_avg).^2, 1);

    N_cur = size(cur_prestim,1); % should equal 10

    % Determine if this is the first FFT block for this frequency/amplitude
    firstfft = (ifft == 1);

    if firstfft
        % This is the first average to be calculated for this current stimulus type
        prev_prestim_avg = [];
        prev_stimresp_avg = [];
        prev_poststimresp_avg = [];
        prev_prestim_sumsq = [];
        prev_stimresp_sumsq = [];
        prev_poststimresp_sumsq = [];
        N_prev = 0;
    else
        
        % Get previous running averages
        if ~isfield(ex{ifreq, iamp}.electrodes, curchan_name) || ...
                ~isfield(ex{ifreq, iamp}.electrodes.(curchan_name), 'running_stats') || ...
                ~isfield(ex{ifreq, iamp}.electrodes.(curchan_name).running_stats, 'prestim') || ...
                ~isfield(ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim, 'runavg') || ...
                length(ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.runavg) < (ifft-1)
            error('Previous running average data not found for channel %s, FFT block %d', curchan_name, ifft-1);
        end

        % Get previous running averages
        prev_prestim_avg = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.runavg{ifft-1};
        prev_stimresp_avg = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.runavg{ifft-1};
        prev_poststimresp_avg = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.runavg{ifft-1};

        prev_prestim_sumsq = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.runsumsq{ifft-1};
        prev_stimresp_sumsq = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.runsumsq{ifft-1};
        prev_poststimresp_sumsq = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.runsumsq{ifft-1};

        N_prev = ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N(ifft-1);
        
        % Debug: Check dimensions before calculation
        fprintf('Debug - Channel %s, FFT %d:\n', curchan_name, ifft);
        fprintf('  prev_prestim_avg size: [%s], N_prev: %d\n', num2str(size(prev_prestim_avg)), N_prev);
        fprintf('  cur_prestim_avg size: [%s], N_cur: %d\n', num2str(size(cur_prestim_avg)), N_cur);
        
        % Ensure dimensional compatibility
        if ~isequal(size(prev_prestim_avg), size(cur_prestim_avg))
            error('Size mismatch: prev_prestim_avg is %s, cur_prestim_avg is %s', ...
                mat2str(size(prev_prestim_avg)), mat2str(size(cur_prestim_avg)));
        end
    end

    N_total = N_prev + N_cur;

    %% Calculate the running average
    % For first FFT block: use current averages directly
    % For subsequent blocks: weighted average of previous and current data
    if firstfft
        new_prestim_avg = cur_prestim_avg;
        new_stimresp_avg = cur_stimresp_avg;
        new_poststimresp_avg = cur_poststimresp_avg;

        new_prestim_sumsq = cur_prestim_sumsq;
        new_stimresp_sumsq = cur_stimresp_sumsq;
        new_poststimresp_sumsq = cur_poststimresp_sumsq;

        if N_total > 1
            new_prestim_std = sqrt(new_prestim_sumsq / (N_total - 1));
            new_stimresp_std = sqrt(new_stimresp_sumsq / (N_total - 1));
            new_poststimresp_std = sqrt(new_poststimresp_sumsq / (N_total - 1));
        else
            warning('Attempted to calculate std with only 1 sample')
        end

    else
        new_prestim_avg = (prev_prestim_avg * N_prev + cur_prestim_avg * N_cur) / (N_cur + N_prev);
        new_stimresp_avg = (prev_stimresp_avg * N_prev + cur_stimresp_avg * N_cur) / (N_cur + N_prev);
        new_poststimresp_avg = (prev_poststimresp_avg * N_prev + cur_poststimresp_avg * N_cur) / (N_cur + N_prev);

        % Calculate combined sum of squares using parallel formula
        prestim_mean_diff_sq = N_prev * N_cur * (prev_prestim_avg - cur_prestim_avg).^2 / (N_prev + N_cur);
        stimresp_mean_diff_sq = N_prev * N_cur * (prev_stimresp_avg - cur_stimresp_avg).^2 / (N_prev + N_cur);
        poststimresp_mean_diff_sq = N_prev * N_cur * (prev_poststimresp_avg - cur_poststimresp_avg).^2 / (N_prev + N_cur);

        new_prestim_sumsq = prev_prestim_sumsq + cur_prestim_sumsq + prestim_mean_diff_sq;
        new_stimresp_sumsq = prev_stimresp_sumsq + cur_stimresp_sumsq + stimresp_mean_diff_sq;
        new_poststimresp_sumsq = prev_poststimresp_sumsq + cur_poststimresp_sumsq + poststimresp_mean_diff_sq;

        if N_total > 1
            new_prestim_std = sqrt(new_prestim_sumsq / (N_total - 1));
            new_stimresp_std = sqrt(new_stimresp_sumsq / (N_total - 1));
            new_poststimresp_std = sqrt(new_poststimresp_sumsq / (N_total - 1));
        else
            warning('Attempted to calculate std with only 1 sample')
        end
    end

    % Store results for current channel in output structure
    FFT_block_avgs.(curchan_name).prestim = new_prestim_avg;
    FFT_block_avgs.(curchan_name).stimresp = new_stimresp_avg;
    FFT_block_avgs.(curchan_name).poststimresp = new_poststimresp_avg;

    FFT_block_avgs.(curchan_name).prestim_std = new_prestim_std;
    FFT_block_avgs.(curchan_name).stimresp_std = new_stimresp_std;
    FFT_block_avgs.(curchan_name).poststimresp_std = new_poststimresp_std;

    % To ex structure
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.runavg{ifft} = new_prestim_avg;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.runavg{ifft} = new_stimresp_avg;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.runavg{ifft} = new_poststimresp_avg;

    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.runstd{ifft} = new_prestim_std;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.runstd{ifft} = new_stimresp_std;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.runstd{ifft} = new_poststimresp_std;

    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.runsumsq{ifft} = new_prestim_sumsq;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.runsumsq{ifft} = new_stimresp_sumsq;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.runsumsq{ifft} = new_poststimresp_sumsq;

    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.prestim.N(ifft) = N_total;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.stimresp.N(ifft) = N_total;
    ex{ifreq, iamp}.electrodes.(curchan_name).running_stats.poststimresp.N(ifft) = N_total;

end


