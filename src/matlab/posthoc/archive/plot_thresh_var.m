%  Amps to include for analysis
to_inc = [{[120 115 110 105 100 95 90]}]; % all points as reference;

f_err = figure;

for i_inc = 1:size(to_inc, 2)
    cur_inc = to_inc{i_inc};
    cur_idxs = find(ismember(amp_sorted,cur_inc));
    f_1 = figure; t1 = tiledlayout('flow','TileSpacing','tight','Padding','tight');

    % Reset variables
    a1_fit = [];
    x0_fit = [];
    k_fit = [];
    y_int = [];
    x_5 = [];

    for i_tri = 1:length(trials_vec)
        % Setup figure
        nexttile(t1)
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

            softplus = @(p,x) p(1)*log1p(exp(p(3)*(x - p(2)))/p(3) + noise_floor_median);
            p0 = [(max(cur_mean)-min(cur_mean))/range(amp_sorted), ...
                median(amp_sorted), 1];
            p = lsqcurvefit(softplus, p0, amp_sorted(cur_idxs), cur_mean, [], [], optimset('Display','off'));

            a1_fit(i_it,i_tri) = p(1);
            x0_fit(i_it,i_tri) = p(2);
            k_fit(i_it,i_tri) = p(3);
            y_int(i_it,i_tri) = noise_floor_median;

            x_5(i_it,i_tri) = p(2) - log(19)/p(3);

            if mod(i_it,10) == 0
                plot(amp_sorted(cur_idxs), cur_mean , 'o-')
                hold on;
                xline(x_5(i_it,i_tri))
            end
        end
        title(sprintf('%d trials %d Channel', cur_trial, cur_channel))
        xlabel('Stimulus Amplitude (dB)')
        ylabel('2f Magnitude (\muV)')
    end
    sgtitle('Threshold estimate varied by N trials included in average')

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