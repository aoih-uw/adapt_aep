clearvars -except ex_save
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))

% Set data location
cd('F:\2026\Research\May Midshipman\2026_05_25\porichthys_notatus_13_20260525\1024 trials')
subjid_vec = {13};
stim_freq = 110;
file_type = 'raw_data';

% 1024 trial specific variables
grand_fft_vec = [];
trials_vec = [16 32 64 128 256 512 1024];
n_it = 1000;
cur_chan = 3; % 3 = skull pierce, 2 = skin, 1 = EKG , 4 = forebrain

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
    diffs_vec = [];

    % Get 2f amplitudes from raw signals
    n_batches = size(ex_save.raw_signals,2);
    for ibatch = 1:n_batches
        clear freq_vec fft_sig
        for itrial = 1:10
            cur_batch = ex_save.raw_signals(1,ibatch).electrodes_microV_ds(itrial,:,cur_chan);
            [~, freq_vec(itrial,:), fft_sig(itrial,:)] = calc_fft(cur_batch,fs(iname));
        end
        [~, min_idx] = min(abs(freq_vec(1,:)-target_freq));
        diffs_vec = [diffs_vec; fft_sig(:,min_idx)]; % 2f magnitude vector across all batches for a single save file
    end

    grand_fft_vec{iname} = diffs_vec; % Collection of all 2f magnitude vectors across all save files
end

[amp_sorted, sorted_idx] = sort(amp);
grand_sorted = grand_fft_vec(sorted_idx);

%  Amps to include for analysis
to_inc = {[120 115 110 105 100 95 90]}; % all points as reference;

f_err = figure;

for i_inc = 1:size(to_inc, 2)
    cur_inc = to_inc{i_inc};
    cur_idxs = find(ismember(amp_sorted,cur_inc));
    f_1 = figure; t1 = tiledlayout('flow','TileSpacing','tight','Padding','tight');
    f_2 = figure; t2 = tiledlayout('flow','TileSpacing','tight','Padding','tight');

    % Reset variables
    a1_fit = [];
    x0_fit = [];
    k_fit = [];
    y_int = [];
    x_5 = [];

    for i_tri = 1:length(trials_vec)
        % Setup figure
        nexttile(t1)
        nexttile(t2)
        cur_trial = trials_vec(i_tri);
        my_trial_set = [];
        for iname = 1:length(cur_idxs)
            cur_idx = cur_idxs(iname);
            cur_set = grand_sorted{cur_idx};
            tmp_it_mean = [];
            tmp_it_std = [];
            for i_it = 1:n_it
                rand_select = randperm(size(cur_set,1),cur_trial);
                tmp_mean = mean(cur_set(rand_select),1);
                tmp_it_mean = [tmp_it_mean; tmp_mean];
            end
            my_trial_set(:,iname) = tmp_it_mean;
        end
       
        for i_it = 1:n_it
            cur_mean = my_trial_set(i_it,:);
            noise_floor_median = min(cur_mean);

            % floor added OUTSIDE the log; x0 is now the true bend point
            softplus = @(p,x) noise_floor_median + p(1)*log1p( exp(p(3)*(x - p(2))) );
            p0 = [ (max(cur_mean)-min(cur_mean))/range(amp_sorted), median(amp_sorted), 0.3 ];

            % bounds keep k sane and x0 inside your stimulus range
            lb = [0,   min(amp_sorted), 1e-3];
            ub = [Inf, max(amp_sorted), 5  ];
            p = lsqcurvefit(softplus, p0, amp_sorted(cur_idxs), cur_mean, lb, ub, optimset('Display','off'));

            a1_fit(i_it,i_tri) = p(1);
            x0_fit(i_it,i_tri) = p(2);
            k_fit(i_it,i_tri) = p(3);
            y_int(i_it,i_tri) = noise_floor_median;

            a1 = p(1); x0 = p(2); k = p(3); nf = noise_floor_median;
            y_floor  = a1 * log1p(nf);            % asymptotic floor of the model
            y_bend   = a1 * log1p(1/k + nf);
            y_target = y_floor + 0.05*(y_bend - y_floor);   % 5% of the way up to the bend

            x_5(i_it,i_tri) = x0 - log(19) / k;

            if mod(i_it,10) == 0
                figure(f_1);
                plot(amp_sorted(cur_idxs), cur_mean , 'o-')
                hold on;
                xline(x_5(i_it,i_tri))

                figure(f_2);
                x_vec = linspace(min(amp_sorted(cur_idxs)), max(amp_sorted(cur_idxs)),200);
                y_vec = softplus(p,x_vec);
                plot(x_vec, y_vec , '-','LineWidth',2)
                hold on;
                xline(x_5(i_it,i_tri))
            end

            mean_2f(i_tri,:) = mean(my_trial_set,1);
            std_2f(i_tri,:) = std(my_trial_set,[],1);
        end
        title(sprintf('%d trials %d Channel', cur_trial, cur_chan))
        xlabel('Stimulus Amplitude (dB)')
        ylabel('2f Magnitude (\muV)')
    end
    sgtitle('Threshold estimate varied by N trials included in average')

    % 2f magnitude at each amplitude and for each trial # condition
    figure;
    for i = 1:size(mean_2f, 1)
    errorbar(amp_sorted(cur_idxs), mean_2f(i,:), std_2f(i,:),'o-')
    hold on;
    end
    lgd = legend(string(trials_vec),'Location','best');
    lgd.Title.String = 'Number of Trials Included';
    title('2f Magnitude at each amp and for each trial # condition')
    xlabel('Stimulus Amplitude (dB SPL)')
    ylabel('2f Magnitude (\muV)')

    % Calculate the mean across all 1000 resamples and how they vary
    mean_x_5 = mean(x_5,1);
    std_x_5 = std(x_5,[],1);

    % Plot the results
    figure(f_err); hold on;
    errorbar(trials_vec, mean_x_5, ...
        std_x_5, 'o-', 'LineWidth', 2, 'MarkerFaceColor', 'auto')
    xlabel('N Trials included in average');
    ylabel('Threshold estimate (dB)')
    title('How do threshold estimates vary by # of trials included in the average?')
    subtitle(sprintf('Channel %d; Error bars: How mean values vary across 1000 random resamples, +/- 1 std', cur_chan))
    xticks(trials_vec)
    ax = gca;
    ax.FontSize = ax.FontSize * 1.1;
    ax.XTickLabelRotation = 45;
    drawnow
end
legends = cellfun(@(v) join(string(v), ", "), to_inc);
lgd = legend(legends, 'Location', 'best');
lgd.Title.String = 'Included data points (dB)';
end