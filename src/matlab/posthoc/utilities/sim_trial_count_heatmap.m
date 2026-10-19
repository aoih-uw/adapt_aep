function [boot_count, F_count] = sim_trial_count_heatmap(amp_vec, boot, cumu, ...
    max_trials, my_chans, my_chans_name, trials_per_block, itvec, CI_vec, my_params)
% Assign Variables
% Bootstrapped based decisions
boot_first = NaN(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));
boot_stable = NaN(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));
boot_inconsist = false(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));

% F statistic based decisions
F_first = NaN(length(my_chans),length(amp_vec));
F_stable = NaN(length(my_chans),length(amp_vec));
F_inconsist =  false(length(my_chans),length(amp_vec));

% General vars
cur_freq = my_params.cur_freq;
my_alpha = my_params.my_alpha;

%% For each iamp and ichan find the first and first *stable* resp_found batch
%% Pause on bootstrapping for now
% % Boostrap Based
% for ii = 1:length(itvec)
%     for iii = 1:length(CI_vec)
%         for iamp = 1:length(amp_vec)
%             for ichan = 1:length(my_chans)
%                 % Get current vector of 1s and 0s
%                 cur_data = boot.diff.resp_found(:,iamp,ichan,ii,iii);
%                 n_filled = find(~isnan(cur_data),1,'last');   %#% What is n_filled doing? [] if all NaN
%                 cur_data = cur_data(1:n_filled);
%                 % Get values
%                 [cur_first, cur_stable, cur_inconsist] = ...
%                     find_first_stable(cur_data, n_filled,max_trials,trials_per_block);
%                 boot_first(ichan,iamp,ii,iii) = cur_first;
%                 boot_stable(ichan,iamp,ii,iii) = cur_stable;
%                 boot_inconsist(ichan,iamp,ii,iii) = cur_inconsist;
%             end
%         end
%     end
% end

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
%% Pause on bootstrapping for now
% % Bootstrap
% figure;
% cur_data = squeeze(boot_first(:,:,end,end));
% cur_title = 'Bootstrap-based';
% plot_heatmap(cur_data,my_chans_name,amp_vec,max_trials,cur_freq,cur_title)

% Fstat
figure;
cur_title = 'F Test | First';
plot_heatmap(F_first,my_chans_name,amp_vec,max_trials,cur_freq,cur_title)

figure;
cur_title = 'F Test | Stable';
plot_heatmap(F_stable,my_chans_name,amp_vec,max_trials,cur_freq,cur_title)

% % Plot Inconsistent Bootstrap decisions
% figure;
% tl = tiledlayout(1,length(my_chans),'TileSpacing','tight','Padding','tight');
% title(tl,'N inconsistent bootstrap decisions')
% n_inconsistent = NaN(length(itvec),length(CI_vec));
% for ichan = 1:length(my_chans)
%     for ii = 1:length(itvec) % n_boot
%         for iii = 1:length(CI_vec) % n_ci
%             cur_data = squeeze(boot_inconsist(ichan,:,ii,iii));
%             n_inconsistent(ii,iii) = sum(cur_data); % Sum across all channels for inconsistent decision
%         end
%     end
%     nexttile
%     imagesc(n_inconsistent)
%     cmax = max(sum(boot_inconsist,2), [], 'all');
%     cmax = max(cmax, 1);
%     clim([0 cmax]);
%     colormap(interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256)))
%     [X,Y] = meshgrid(1:length(CI_vec), 1:length(itvec));
%     text(X(:), Y(:), string(n_inconsistent(:)), ...
%         'HorizontalAlignment','center','Color','k');
%     set(gca,'XTick',1:length(CI_vec),'XTickLabel',string(CI_vec), ...
%         'YTick',1:length(itvec),'YTickLabel',string(itvec))
%     xlabel('Confidence Interval')
%     ylabel('N Bootstrap Iterations')
%     title(sprintf('Channel: %s',my_chans_name{ichan}))
%     sgtitle(sprintf('Inconsistent decision: %d Hz ', cur_freq))
% end

% Store variables
boot_count = struct('first',boot_first,'stable',boot_stable,'inconsist',boot_inconsist);
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
