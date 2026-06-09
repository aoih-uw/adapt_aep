clearvars -except ex_save
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))

% Set data location
cd 'F:\2026\Research\May Midshipman\2026_05_26\porichthys_notatus_14_20260526\1024_trials'
subjid_vec = {14};
stim_freq = 110;
file_type = 'raw_data';

% 1024 trial specific variables
grand_fft_vec = [];
trials_vec = [16 32 64 128 256 512 1024];
n_it = 1000;
my_chans = [2,3,4]; % 3 = skull pierce, 2 = skin, 1 = EKG , 4 = forebrain

for isubj = 1:length(subjid_vec)
    % Get file names
    subjid = subjid_vec{isubj};
    my_names = get_file_names(subjid, stim_freq, [], file_type);

    % Load in files
    for iname = 1:length(my_names)
        current_file = my_names{iname};
        [ex_save, cur_freq, cur_amp] = load_my_file(current_file, iname, my_names);
        amp(iname) = cur_amp;
        fs(iname) = ex_save.ds_fs;
        target_freq = 2*cur_freq;
        grand_ex_save{iname} = ex_save;
    end

    f_err = figure;
    for ichan = 1:length(my_chans)
        cur_chan = my_chans(ichan);
        grand_fft_vec = [];
        f_1 = figure; t1 = tiledlayout('flow','TileSpacing','tight','Padding','tight');
        f_2 = figure; t2 = tiledlayout('flow','TileSpacing','tight','Padding','tight');

        for iname = 1:length(my_names)
            diffs_vec = [];
            % Get 2f amplitudes from raw signals
            n_batches = size(grand_ex_save{iname}.raw_signals,2);
            for ibatch = 1:n_batches
                clear freq_vec fft_sig
                for itrial = 1:10
                    cur_batch = grand_ex_save{iname}.raw_signals(1,ibatch).electrodes_microV_ds(itrial,:,cur_chan);
                    [~, freq_vec(itrial,:), fft_sig(itrial,:)] = calc_fft(cur_batch,fs(iname));
                end
                [~, min_idx] = min(abs(freq_vec(1,:)-target_freq));
                diffs_vec = [diffs_vec; fft_sig(:,min_idx)]; % 2f magnitude vector across all batches for a single save file
            end
            grand_fft_vec{iname} = diffs_vec; % Collection of all 2f magnitude vectors across all save files
        end

        [amp_sorted, sorted_idx] = sort(amp);
        grand_sorted = grand_fft_vec(sorted_idx);

        % Reset variables
        slope_1_fit = [];
        elbow_1_fit = [];
        slope_2_fit = [];
        y_int = [];
        x_1 = [];

        for i_tri = 1:length(trials_vec)
            % Setup figure
            nexttile(t1)
            nexttile(t2)
            cur_trial = trials_vec(i_tri);
            my_trial_set = [];
            for iname = 1:length(my_names)
                cur_set = grand_sorted{iname};
                tmp_it_mean = [];
                tmp_it_std = [];
                for i_it = 1:n_it
                    rand_select = randperm(size(cur_set,1),cur_trial);
                    tmp_mean = mean(cur_set(rand_select),1);
                    tmp_std = std(cur_set(rand_select),[],1);
                    tmp_it_mean = [tmp_it_mean; tmp_mean];
                    tmp_it_std = [tmp_it_std; tmp_std];
                end
                my_trial_set(:,iname) = tmp_it_mean;
                my_std_set(:,iname) = tmp_it_std;
            end

            for i_it = 1:n_it
                cur_mean = my_trial_set(i_it,:);
                cur_std = my_std_set(i_it,:);

                noise_floor_center = cur_mean(1);
                % Model
                p0 = [0.1,  100,  0.5,  110];
                lb  = [0,   min(amp_sorted),  0,  min(amp_sorted)];
                ub  = [Inf, max(amp_sorted), Inf, max(amp_sorted)];

                piecewise2 = @(p,x) noise_floor_center + p(1)*max(x-p(2),0) + p(3)*max(x-p(4),0);
                p = lsqcurvefit(piecewise2, p0, amp_sorted, cur_mean, lb, ub, optimset('Display','off'));
                
                slope_1_fit(i_it,i_tri) = p(1);
                elbow_1_fit(i_it,i_tri) = p(2);
                slope_2_fit(i_it,i_tri) = p(3);
                elbow_2(i_it,i_tri) = p(4);
                y_int(i_it,i_tri) = noise_floor_center;
                
                x_vec = linspace(min(amp_sorted), max(amp_sorted),500);
                y_vec = piecewise2(p,x_vec);
                x_1(i_it,i_tri) = p(2);

                if mod(i_it,100) == 0
                    figure(f_1);
                    errorbar(amp_sorted, cur_mean , cur_std,'o-')
                    hold on;
                    xline(x_1(i_it,i_tri))

                    title(sprintf('%d trials', cur_trial))
                    xlabel('Stimulus Amplitude (dB)')
                    ylabel('2f Magnitude (\muV)')

                    figure(f_2);
                    plot(x_vec, y_vec , '-','LineWidth',2)
                    hold on;
                    xline(x_1(i_it,i_tri))

                    title(sprintf('%d trials', cur_trial))
                    xlabel('Stimulus Amplitude (dB)')
                    ylabel('2f Magnitude (\muV)')
                end

                mean_2f(i_tri,:) = mean(my_trial_set,1);
                std_2f(i_tri,:) = std(my_trial_set,[],1);
            end
        end

        % Set titles
        figure(f_1);
        sgtitle(sprintf('Channel %d: Threshold estimate varied by N trials included in average', cur_chan))

        figure(f_2);
        sgtitle(sprintf('Channel %d: Threshold estimate varied by N trials included in average', cur_chan))

        % % 2f magnitude at each amplitude and for each trial # condition
        % figure;
        % for i = 1:size(mean_2f, 1)
        % errorbar(amp_sorted(cur_idxs), mean_2f(i,:), std_2f(i,:),'o-')
        % hold on;
        % end
        % lgd = legend(string(trials_vec),'Location','best');
        % lgd.Title.String = 'Number of Trials Included';
        % title('2f Magnitude at each amp and for each trial # condition')
        % xlabel('Stimulus Amplitude (dB SPL)')
        % ylabel('2f Magnitude (\muV)')

        % Calculate the mean across all 1000 resamples and how they vary
        mean_x_5 = mean(x_1,1);
        std_x_5 = std(x_1,[],1);

        % Plot the results
        figure(f_err); hold on;
        errorbar(trials_vec, mean_x_5, ...
            std_x_5, 'o-', 'LineWidth', 2, 'MarkerFaceColor', 'auto')
    end

    % Finalize f_err
    figure(f_err);
    xlabel('N Trials included in average')
    ylabel('Threshold estimate (dB)')
    title('How do threshold estimates vary by # of trials included in the average?')
    legend('Location', 'best')
    ax = gca;
    ax.FontSize = ax.FontSize * 1.1;
    ax.XTickLabelRotation = 45;
    xticks(trials_vec)
    drawnow
end