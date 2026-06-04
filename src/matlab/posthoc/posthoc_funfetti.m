% posthoc_ekg

addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))
cd 'F:\2026\Research\May Midshipman\2026_06_02\porichthys_notatus_16_20260602\benzo'
% Assign vars
subjid_vec = {16};
stim_freq = 110;
stim_amp = [];
file_type = 'raw_data';
my_channels = [2,3,4];
my_channels_names = {'1 mm', '2 mm', 'Forebrain'};
KO_time = datetime(2026, 6, 2, 10, 56, 0); % no timezone


for isubj = 1:length(subjid_vec)
    % Get filename
    subjid = subjid_vec{isubj};
    my_names = get_file_names(subjid, stim_freq, stim_amp, file_type);

    cur_name = figure;
    for ichan = 1:length(my_channels)
        cur_chan = my_channels(ichan);
        for iname = 1:length(my_names)
            current_file = my_names{iname};
            [ex, cur_freq, cur_amp] = load_my_file(current_file, iname, my_names);
            freq_vec(iname) = cur_freq;
            target_freq = cur_freq*2;
            amp_vec(iname) = cur_amp;
            ds = ex.ds_fs;

            n_batches = size(ex.raw_signals,2);
            vec_2f = [];
            my_time = [];

            for ibatch = 1:n_batches
                clear freq_vec fft_sig
                for itrial = 1:10
                    cur_batch = ex.raw_signals(1,ibatch).electrodes_microV_ds(itrial,:,cur_chan);
                    [~, freq_vec(itrial,:), fft_sig(itrial,:)] = calc_fft(cur_batch,ds);
                end
                [~, min_idx] = min(abs(freq_vec(1,:)-target_freq));
                vec_2f = [vec_2f; fft_sig(:,min_idx)]; % 2f magnitude vector across all batches for a single save file
                my_time = [my_time datetime(ex.raw_signals(1,ibatch).time_stamp_ds, 'InputFormat', 'yyyyMMdd_HHmmss')];
            end

            grand_fft_vec{iname,ichan} = vec_2f; % Collection of all 2f magnitude vectors across all save files
            grand_time_stamp{iname,ichan} = my_time;

            % Figure;
            ts = datetime(grand_time_stamp{1,ichan}, 'TimeZone', '');
            t_diffs = minutes(ts - KO_time);
            mean_every_10 = mean(reshape(vec_2f, 10, []), 1);
            std_every_10 = std(reshape(vec_2f, 10, []), [], 1);
            figure(cur_name)
            hold on;
            errorbar(t_diffs,mean_every_10, std_every_10,'LineWidth',2);
            title('2f Magnitude Tracking after Benzocaine KO')
            xlabel('# Minutes post KO')
            ylabel('2f Magnitude \muV')
            legend(string(my_channels_names),'Location','best')
        end
    end


end
