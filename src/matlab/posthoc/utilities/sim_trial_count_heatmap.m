function [resp_stable, resp_first, inconsistent_vec] = sim_trial_count_heatmap(amp_vec, boot,...
    max_trials, my_chans, my_chans_name, trials_per_block, itvec, CI_vec,my_params)
% Assign Variables
resp_first = NaN(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));
resp_stable = NaN(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));
inconsistent_vec = false(length(my_chans),length(amp_vec),length(itvec),length(CI_vec));
cur_freq = my_params.cur_freq;

%% For each iamp and ichan find the first and first *stable* resp_found batch
for ii = 1:length(itvec)
    for iii = 1:length(CI_vec)
        for iamp = 1:length(amp_vec)
            for ichan = 1:length(my_chans)
                cur_data = boot.diff.resp_found(:,iamp,ichan,ii,iii);
                n_filled = find(~isnan(cur_data),1,'last');   % [] if all NaN
                cur_data = cur_data(1:n_filled);

                %% First response = find('first'); Stable response is find('last')
                % Find the first resp_found
                first_resp = find(cur_data == 1,1,'first');
                if isempty(n_filled)
                    fprintf('There are NaNs in boot.diff.resp_found...') % all NaN
                    % resp_first(ichan,iamp,ii,iii) = NaN;
                elseif isempty(first_resp)            % No response at any point
                    resp_first(ichan,iamp,ii,iii) = max_trials;
                else
                    resp_first(ichan,iamp,ii,iii) = first_resp*trials_per_block;
                end

                % Find the last stable resp_found batch
                last_no_resp = find(cur_data == 0,1,'last');
                if isempty(n_filled)                    % all NaN
                    fprintf('There are NaNs in boot.diff.resp_found...') % all NaN
                elseif isempty(last_no_resp)            % never a no-response
                    resp_stable(ichan,iamp,ii,iii) = trials_per_block;
                elseif last_no_resp == n_filled         % final filled batch still no-response
                    resp_stable(ichan,iamp,ii,iii) = max_trials;
                else
                    resp_stable(ichan,iamp,ii,iii) = (last_no_resp+1)*trials_per_block;
                end

                % Find inconsistent bootstrap decision across all available
                % batches. -1 means we went from a value of 1 to 0 from
                % left to right in the vector... Ideally after the
                % bootstrapping finds a response, it will stick with that
                % decision.
                inconsistent_vec(ichan,iamp,ii,iii) = any(diff(cur_data(:)) == -1);
            end
        end
    end
end

%% Plot trial count heatmap
% min num of trials needed to find reliable resp_found (i.e., no more no resp_found after resp_found)
% Plot only the max iteration and CI values
figure;
cur_data = squeeze(resp_stable(:,:,end,end));
cur_data(cur_data == max_trials) = NaN;
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
            n_inconsistent(ii,iii) = sum(cur_data); % Sum across all channels for inconsistent decision
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
