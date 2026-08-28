function resp_found_vec = sim_trial_count_heatmap(amp_vec, simu,...
    resp_found_vec, max_trials, my_chans, my_chans_name, trials_per_block, itvec, CI_vec,my_params)
cur_freq = my_params.cur_freq;
%% For each iamp and ichan find the first *stable* resp_found batch
for ii = 1:length(itvec)
    for iii = 1:length(CI_vec)
        for iamp = 1:length(amp_vec)
            for ichan = 1:length(my_chans)
                cur_data = simu.resp_found(:,iamp,ichan,ii,iii);
                n_filled = find(~isnan(cur_data),1,'last');   % [] if all NaN
                cur_data = cur_data(1:n_filled);

                % Find the last stable resp_found batch
                last_no_resp = find(cur_data == 0,1,'last');
                if isempty(n_filled)                    % all NaN
                    resp_found_vec(ichan,iamp,ii,iii) = NaN;
                elseif isempty(last_no_resp)            % never a no-response
                    resp_found_vec(ichan,iamp,ii,iii) = trials_per_block;
                elseif last_no_resp == n_filled         % final filled batch still no-response
                    resp_found_vec(ichan,iamp,ii,iii) = NaN;
                else
                    resp_found_vec(ichan,iamp,ii,iii) = (last_no_resp+1)*trials_per_block;
                end

                % Find inconsistent bootstrap decision across all available
                % batches
                inconsistent_vec(ichan,iamp,ii,iii) = any(diff(cur_data(:)) == -1);
            end
        end
    end
end

%% Plot trial count heatmap
% min num of trials needed to find reliable resp_found (i.e., no more no resp_found after resp_found)
% Plot only the max iteration and CI values
figure;
cur_data = squeeze(resp_found_vec(:,:,end,end));
h = heatmap(cur_data);              % keep NaNs
h.MissingDataColor = tableau_10('grey');   % grey out the NaN cells
h.XDisplayLabels = string(amp_vec);
h.YDisplayLabels = my_chans_name;
h.ColorbarVisible = 'off';
h.Colormap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
title(sprintf('N Trials Needed: %d Hz ',cur_freq))
h.XLabel = 'Stimulus Amplitude (dB SPL)';

%% Plot inconsistent decision rates by CI rate and n_bootstrap
figure;
tl = tiledlayout(1,length(my_chans),'TileSpacing','tight','Padding','tight');
title(tl,'N inconsistent bootstrap decisions')
n_inconsistent = NaN(length(itvec),length(CI_vec));
for ichan = 1:length(my_chans)
for ii = 1:length(itvec) % n_boot
    for iii = 1:length(CI_vec) % n_ci
        cur_data = squeeze(inconsistent_vec(ichan,:,ii,iii));
        n_inconsistent(ii,iii) = sum(cur_data);
    end
end
nexttile
imagesc(n_inconsistent)
cmax = max(sum(inconsistent_vec,2), [], 'all');
cmax = max(cmax, 1);
clim([0 cmax]);
colormap(interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256)))
[X,Y] = meshgrid(1:length(CI_vec), 1:length(itvec));
text(X(:), Y(:), string(n_inconsistent(:)), ...
        'HorizontalAlignment','center','Color','k');
set(gca,'XTick',1:length(CI_vec),'XTickLabel',string(CI_vec), ...
    'YTick',1:length(itvec),'YTickLabel',string(itvec))
xlabel('Confidence Interval')
ylabel('N Bootstrap Iterations')
title(sprintf('Channel: %s',my_chans_name{ichan}))
sgtitle(sprintf('Inconsistent decision: %d Hz ', cur_freq))
end

%% Calculate time needed
% % For a 600 ms stimulus, and test at 8 amplitudes
% adaptive_trials = squeeze(resp_found_vec(:,1:2:16,end));
% adaptive_trials(isnan(adaptive_trials)) = max_trials;
% static_trials = ones(size(adaptive_trials,1),size(adaptive_trials,2))*max_trials;
% time_mat = ones(size(adaptive_trials,1),size(adaptive_trials,2))*(600/1000/60); % 600 ms in minutes
% 
% adaptive_time = adaptive_trials.*time_mat;
% static_time = static_trials.*time_mat;
% 
% clean_adaptive = cumsum(adaptive_time(2,:));
% clean_static = cumsum(static_time(2,:));
% 
% figure;plot(amp_vec,clean_adaptive,'-o','Color',tableau_10('blue'),'LineWidth',2, 'MarkerFaceColor',tableau_10('blue'))
% hold on;
% plot(amp_vec,clean_static,'-o','Color',tableau_10('orange'),'LineWidth',2, 'MarkerFaceColor',tableau_10('orange'))
% xlabel('Stimulus Amplitude')
% ylabel('Cumulative time testing (min)')
% title('Over 15 minutes saved using adaptive trial presentation')
% legend('Adaptive trial presentation','Static trial count')
