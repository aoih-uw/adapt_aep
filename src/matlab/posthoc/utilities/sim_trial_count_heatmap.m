function [F_count] = sim_trial_count_heatmap(amp_vec, cumu, ...
    max_trials, my_chans, my_chans_name, trials_per_block, my_params)
%% Assign Variables
% F statistic based decisions
F_first = NaN(length(my_chans),length(amp_vec));
F_stable = NaN(length(my_chans),length(amp_vec));
F_inconsist =  false(length(my_chans),length(amp_vec));

% General vars
cur_freq = my_params.cur_freq;
my_alpha = my_params.my_alpha;

%% For each iamp and ichan find the first and first *stable* resp_found batch
% F Stat Based
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans)
        % 2 column is p value
        cur_data = cumu.F_stats(:,2,iamp,ichan);
        n_filled = find(~isnan(cur_data),1,'last');
        cur_data = cur_data(1:n_filled) < my_alpha;
        % Get values
        [cur_first, cur_stable, cur_inconsist] = ...
            find_first_stable(cur_data, n_filled,max_trials,trials_per_block);
        F_first(ichan,iamp) = cur_first;
        F_stable(ichan,iamp) = cur_stable;
        F_inconsist(ichan,iamp) = cur_inconsist;
    end
end

%% Plots
% Plot Trials Needed Heatmap
% Fstat
figure;
cur_title = 'F Test | First';
plot_heatmap(F_first,my_chans_name,amp_vec,max_trials,cur_freq,cur_title)

figure;
cur_title = 'F Test | Stable';
plot_heatmap(F_stable,my_chans_name,amp_vec,max_trials,cur_freq,cur_title)

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
