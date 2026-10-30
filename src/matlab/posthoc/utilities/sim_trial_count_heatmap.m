function [F_count] = sim_trial_count_heatmap(amp_vec, cumu, ...
    max_trials, my_chans, my_chans_name, trials_per_block, my_params)
%% Assign Variables
n_boot = my_params.n_boot;
cur_freq = my_params.cur_freq;
my_alpha = my_params.my_alpha;

% F statistic based decisions
F_first = NaN(length(my_chans),length(amp_vec),n_boot);
F_stable = NaN(length(my_chans),length(amp_vec),n_boot);
F_inconsist =  false(length(my_chans),length(amp_vec),n_boot);

%% For each iamp and ichan find the first and first *stable* resp_found batch
% F Stat Based
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        for iboot = 1:n_boot
            % 2 column is p value
            cur_data = cumu.F_stats(:,2,iamp,ichan,iboot);
            n_filled = find(~isnan(cur_data),1,'last');
            cur_data = cur_data(1:n_filled) < my_alpha;
            % Get values
            [cur_first, cur_stable, cur_inconsist] = ...
                find_first_stable(cur_data, n_filled,max_trials,trials_per_block);
            F_first(ichan,iamp,iboot) = cur_first;
            F_stable(ichan,iamp,iboot) = cur_stable;
            F_inconsist(ichan,iamp,iboot) = cur_inconsist;
        end
    end
end

%% Plots
% Plot Trials Needed Heatmap
plot_boot(F_first, my_chans_name, amp_vec, max_trials, cur_freq, 'F Test | First')
plot_boot(F_stable, my_chans_name, amp_vec, max_trials, cur_freq,'F Test | Stable')

%% Store variables
F_count    = struct('first',F_first,'stable',F_stable,'inconsist',F_inconsist);

end

%% Local Functions
%% Plot trial count heatmap
% min num of trials needed to find reliable resp_found (i.e., no more no resp_found after resp_found)
% Plot only the max iteration and CI values
function plot_heatmap(cur_data,my_chans_name,amp_vec,max_trials,cur_freq,cur_title)
cur_data(cur_data == max_trials) = NaN;
h = heatmap(cur_data);              % keep NaNs
h.MissingDataColor = tableau_10('grey');   % grey out the NaN cells
h.XDisplayLabels = string(amp_vec);
h.YDisplayLabels = my_chans_name;
h.ColorbarVisible = 'off';
h.Colormap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
title(sprintf('%s | N Trials Needed: %d Hz ',cur_title,cur_freq))
h.XLabel = 'Stimulus Amplitude (dB SPL)';
end

function plot_boot(F, my_chans_name, amp_vec, max_trials, cur_freq, cur_title)
keep = ~contains(my_chans_name, {'EKG', 'Forebrain'}, 'IgnoreCase', true);
F = F(keep,:,:); my_chans_name = my_chans_name(keep);

figure; plot_heatmap(F(:,:,end), my_chans_name, amp_vec, max_trials, cur_freq, cur_title)

boot = F(:,:,1:end-1);
boot(boot == max_trials) = NaN;
my_mean = mean(boot,3,'omitnan');
ci = prctile(boot,[2.5 97.5],3);

figure; t = tiledlayout('flow','TileSpacing','tight','Padding','tight');
for ichan = 1:size(F,1)
    cur_color = select_chan_color(ichan);
    nexttile; hold on
    errorbar(amp_vec, my_mean(ichan,:), ...
        my_mean(ichan,:)-ci(ichan,:,1), ci(ichan,:,2)-my_mean(ichan,:), ...
        'o','Color',cur_color,'MarkerFaceColor',cur_color)
    plot(amp_vec, F(ichan,:,end), '*', 'Color',cur_color,'MarkerSize',15)
    yline(260)
    title(my_chans_name{ichan})
end
xlabel(t, 'Stimulus Amplitude (dB SPL)'); ylabel(t, 'N Trials Needed')
title(t, sprintf('%s | Mean & 95%% CI: %d Hz', cur_title, cur_freq))
end