% posthoc_ekg
clearvars grand_fft_vec grand_time_stamp

% Assign vars
my_channels = [2,3,4];
chan_colors = {tableau_10('blue'), tableau_10('orange'), tableau_10('green')};
KO_time = datetime(2026, 6, 22, 10, 29, 0); % no timezone
for isubj = 1:length(subjid_list)
    % Get filename
    subjid = subjid_list{isubj};
    cur_name = figure;
    n_chans = length(my_channels);
    tiledlayout(2, n_chans, 'TileSpacing', 'tight', 'Padding', 'tight')

    % Pre-create axes: first n_chans for 2f, next n_chans for RMS
    for ichan = 1:n_chans
        ax1(ichan) = nexttile(ichan); hold(ax1(ichan), 'on');
    end
    for ichan = 1:n_chans
        ax2(ichan) = nexttile(n_chans + ichan); hold(ax2(ichan), 'on');
    end

    for ichan = 1:length(my_channels)
        cur_chan = my_channels(ichan);
        for iname = 1:length(my_names{isubj})
            ds = my_fs(iname,isubj);
            target_freq = freq_2f(iname,isubj);
            n_batches = size(grand_ex_save{iname,isubj}.raw_signals,2);
            vec_2f = [];
            my_time = [];
            silent_rms = [];
            for ibatch = 1:n_batches
                clear freq_vec fft_sig tmp_silent_rms
                cur_jitter_set = grand_ex_save{iname,isubj}.block_level_info(ibatch).jitter;
                for itrial = 1:10
                    silent_slice_end = round(cur_jitter_set(itrial) + (50/1e3*ds)); % 50 ms gap at the beginning
                    cur_batch = grand_ex_save{iname,isubj}.raw_signals(1,ibatch).electrodes_microV_ds(itrial,:,cur_chan);
                    silent_slice = cur_batch(1:silent_slice_end);
                    tmp_silent_rms(itrial) = rms(silent_slice);
                    [~, freq_vec(itrial,:), fft_sig(itrial,:)] = calc_fft(cur_batch,ds);
                end
                [~, min_idx] = min(abs(freq_vec(1,:)-target_freq));
                vec_2f = [vec_2f; fft_sig(:,min_idx)]; % 2f magnitude vector across all batches for a single save file
                my_time = [my_time datetime(grand_ex_save{iname,isubj}.raw_signals(1,ibatch).time_stamp_ds, 'InputFormat', 'yyyyMMdd_HHmmss')];
                silent_rms = [silent_rms; tmp_silent_rms'];
            end

            grand_fft_vec{iname,ichan} = vec_2f; % Collection of all 2f magnitude vectors across all save files
            grand_time_stamp{iname,ichan} = my_time;
            grand_silent_rms{iname,ichan} = silent_rms;

            % Figure;
            ts = datetime(grand_time_stamp{iname,ichan}, 'TimeZone', '');
            t_diffs = minutes(ts - KO_time);
            mean_every_10 = mean(reshape(vec_2f, 10, []), 1);
            std_every_10 = std(reshape(vec_2f, 10, []), [], 1);
            mean_rms_10 = mean(reshape(silent_rms,10,[]),1);
            std_rms_10 = std(reshape(silent_rms,10,[]),[],1);
            p = polyfit(t_diffs, mean_every_10, 1);
            errorbar(ax1(ichan), t_diffs, mean_every_10, std_every_10, 'LineWidth', 2, 'Color', chan_colors{ichan});
            plot(ax1(ichan), t_diffs, polyval(p, t_diffs), 'Color', tableau_10('grey'), 'LineWidth', 3);
            title(ax1(ichan), sprintf('2f Magnitude - Ch%d', cur_chan));
            ylabel(ax1(ichan), '2f Magnitude (\muV)');

            errorbar(ax2(ichan), t_diffs, mean_rms_10, std_rms_10, 'LineWidth', 2, 'Color', chan_colors{ichan});
            title(ax2(ichan), sprintf('Silent RMS - Ch%d', cur_chan));
            ylabel(ax2(ichan), 'RMS (\muV)');
        end
        xlabel(ax2(ichan), 'Minutes post KO');
    end
end
