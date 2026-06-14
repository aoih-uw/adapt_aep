% posthoc_ekg
clearvars grand_fft_vec grand_time_stamp

% Assign vars
my_channels = [2,3,4];
chan_colors = {tableau_10('blue'), tableau_10('orange'), tableau_10('green')};
KO_time = datetime(2026, 6, 2, 10, 56, 0); % no timezone
for isubj = 1:length(subjid_list)
    % Get filename
    subjid = subjid_list{isubj};
    cur_name = figure;
    for ichan = 1:length(my_channels)
        cur_chan = my_channels(ichan);
        for iname = 1:length(my_names{isubj})
            ds = my_fs(iname,isubj);
            target_freq = freq_2f(iname,isubj);
            n_batches = size(grand_ex_save{iname,isubj}.raw_signals,2);
            vec_2f = [];
            my_time = [];
            for ibatch = 1:n_batches
                clear freq_vec fft_sig
                for itrial = 1:10
                    cur_batch = grand_ex_save{iname,isubj}.raw_signals(1,ibatch).electrodes_microV_ds(itrial,:,cur_chan);
                    [~, freq_vec(itrial,:), fft_sig(itrial,:)] = calc_fft(cur_batch,ds);
                end
                [~, min_idx] = min(abs(freq_vec(1,:)-target_freq));
                vec_2f = [vec_2f; fft_sig(:,min_idx)]; % 2f magnitude vector across all batches for a single save file
                my_time = [my_time datetime(grand_ex_save{iname,isubj}.raw_signals(1,ibatch).time_stamp_ds, 'InputFormat', 'yyyyMMdd_HHmmss')];
            end

            grand_fft_vec{iname,ichan} = vec_2f; % Collection of all 2f magnitude vectors across all save files
            grand_time_stamp{iname,ichan} = my_time;

            % Figure;
            ts = datetime(grand_time_stamp{iname,ichan}, 'TimeZone', '');
            t_diffs = minutes(ts - KO_time);
            mean_every_10 = mean(reshape(vec_2f, 10, []), 1);
            std_every_10 = std(reshape(vec_2f, 10, []), [], 1);
            figure(cur_name)
            hold on;
            p = polyfit(t_diffs,mean_every_10,1);
            errorbar(t_diffs, mean_every_10, std_every_10, 'LineWidth', 2, 'Color', chan_colors{ichan});
            plot(t_diffs, polyval(p, t_diffs),'Color',tableau_10('grey'), 'LineWidth', 3);
            title('2f Magnitude Tracking after Benzocaine KO')
            xlabel('# Minutes post KO')
            ylabel('2f Magnitude \muV')
        end
    end
end
