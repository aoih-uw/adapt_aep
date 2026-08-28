function [p_chan, thresh_ci, stable_n] = ...
    fit_low_CI_model(amp_vec, lower_ci_vec, boot_std_vec, resp_found_vec, ...
    trials_per_block, max_trials, my_chans_name, cur_freq, my_tag, yes_plot)

% Preallocate
x_vec = linspace(min(amp_vec), max(amp_vec), 2000);
thresh_ci = NaN(length(my_chans_name),1);
p_chan = NaN(size(my_chans_name,2),4);
stable_n = [];

%% Lower CI based growth function (SOFTPLUS)
    %% Generate vector simulating live experiment with uneven trial counts based on bootstrap decisions
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans_name)
            cur_idx = resp_found_vec(ichan,iamp,end,end)/trials_per_block;
            if isnan(cur_idx) % Get the mean and sem of the last measured batch
                growth_func_mean(ichan,iamp) = lower_ci_vec(end,iamp,ichan);
                growth_func_std(ichan,iamp) = boot_std_vec(end,iamp,ichan);
            else % Get the valid resp_found idx and extract its mean/sem
                growth_func_mean(ichan,iamp) = lower_ci_vec(cur_idx,iamp,ichan);
                growth_func_std(ichan,iamp) = boot_std_vec(cur_idx,iamp,ichan);
            end
        end
    end


if yes_plot
    figure; tiledlayout(1,length(my_chans_name),'TileSpacing','tight','Padding','tight');
end

% Loop through data
for ichan = 1:length(my_chans_name)
    if yes_plot
        nexttile
    end
    cur_color = select_chan_color(ichan);
        cur_y = growth_func_mean(ichan,:);
        cur_weights = growth_func_std(ichan,:);

        if any(isnan(cur_y)), continue; end

        % Fit softplus
        [p, ~, ~, softplus,fit_ok, ~] = param_softplus(cur_y, cur_weights, reshape(amp_vec,1,[]), [], 1);

        % Create fitted softplus y vector
        y_vec = softplus(p, x_vec);

        % Find and assign 0 crossing threshold value
        if y_vec(1) < 0
            cross_idx = find(y_vec >= 0, 1, 'first');
            if ~isempty(cross_idx)
                thresh_ci(ichan) = x_vec(cross_idx);
            end
        end

        % Plot model fit
        if yes_plot
            plot(x_vec,y_vec,'Color',cur_color,'LineWidth',1.5)
            hold on;
            plot(amp_vec, cur_y, 'o','Color',cur_color)
            yline(0,'--')
            xline(thresh_ci(ichan), '--', sprintf('%.2f', thresh_ci(ichan)))
            xlabel('Stimulus Amplitude')
            if ichan == 1, ylabel('Lower CI Value'); end
            title(sprintf('%s', my_chans_name{ichan}))
            hold on;
        end

        % Save model fit parameters
        p_chan(ichan,:) = p;

    if yes_plot
        xregion(min(thresh_ci(ichan)), max(thresh_ci(ichan)), ...
            'FaceColor', tableau_10('grey'), 'FaceAlpha', 0.2)
    end

end

if yes_plot
    sgtitle(sprintf('%d Hz %s: Softplus fit to lower CI value',cur_freq,my_tag))
    linkaxes
end

% % Find N trials at which threshold estimate stabilizes
% tol = 3; % dB tolerance band
% n_trials = trials_per_block:trials_per_block:max_trials;
% stable_n = NaN(1,length(my_chans_name));
% for ichan = 1:length(my_chans_name)
%     % Get vector of thresholds
%     y_vec = thresh_ci(ichan);
%     if isnan(y_vec(end))
%         stable_n(ichan) = NaN;
%     else
%         non_nan_idxs = find(~isnan(y_vec));
%         non_nan_y_vec = y_vec(non_nan_idxs);
%         last_bad = find(abs(non_nan_y_vec - y_vec(end)) > tol, 1, 'last');
%         last_bad = non_nan_idxs(last_bad);
%         if isempty(last_bad)
%             stable_n(ichan) = n_trials(1);
%         elseif  ~isnan(y_vec(last_bad+1))
%             stable_n(ichan) = n_trials(last_bad+1);
%         elseif isnan(y_vec(last_bad+1))
%             fprintf('last bad + 1 was NaN')
%         end
%     end
% end

% % Plot change in threshold estimate across batches of 10
% if yes_plot
%     figure; tiledlayout(1,length(my_chans_name),'Padding','tight','TileSpacing','tight');
%     for ichan = 1:length(my_chans_name)
%         nexttile
%         cur_color = select_chan_color(ichan);
% 
%         plot(n_trials,thresh_ci(ichan),'-o','Color',cur_color,'LineWidth',2,'MarkerFaceColor',cur_color)
%         hold on;
%         xline(thresh_ci(ichan))
%         title(sprintf('%s', my_chans_name{ichan}))
%         xlabel('N trials in AEP average')
%         ylabel('Estimated threshold (dB SPL)')
%     end
%     sgtitle(sprintf('%d Hz %s: Lower CI-based threshold value estimate',cur_freq,my_tag))
%     linkaxes
%     ylim([95 140])
%     xlim([0 260])
% end