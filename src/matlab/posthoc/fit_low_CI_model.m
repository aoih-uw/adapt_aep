function [low_growth] = ...
    fit_low_CI_model(amp_vec, lower_ci_vec, resp_found_vec, noise_floor,...
    trials_per_block, max_trials, my_chans_name, cur_freq, my_tag, yes_plot)

my_reso = 2000;
cur_thresh = NaN;
% Preallocate
low_growth.mean = NaN(length(my_chans_name),length(amp_vec));
low_growth.trials = NaN(length(my_chans_name),length(amp_vec));
low_growth.noise = NaN(length(my_chans_name),length(amp_vec));

low_growth.x_vec = NaN(1,my_reso,length(my_chans_name));
low_growth.y_vec = NaN(1,my_reso,length(my_chans_name));
low_growth.thresh_ci = NaN(length(my_chans_name),1);
low_growth.p = NaN(length(my_chans_name),4);

x_vec = linspace(min(amp_vec), max(amp_vec), my_reso);
p_chan = NaN(size(my_chans_name,2),4);
stable_n = [];

%% Lower CI based growth function (SOFTPLUS)
    %% Generate vector simulating live experiment with uneven trial counts based on bootstrap decisions
    for iamp = 1:length(amp_vec)
        for ichan = 1:length(my_chans_name)
            trials_needed = resp_found_vec(ichan,iamp,end,end); % Trials needed to find a response
            cur_idx = trials_needed/trials_per_block;
            if isnan(cur_idx) % Get the mean and sem of the last measured batch
                cur_idx = size(lower_ci_vec,1);  % no response found: all batches used
                low_growth.mean(ichan,iamp) = lower_ci_vec(end,iamp,ichan);
                low_growth.noise(ichan,iamp) = noise_floor(end,iamp,ichan);
            else % Get the valid resp_found idx and extract its mean/sem
                low_growth.mean(ichan,iamp) = lower_ci_vec(cur_idx,iamp,ichan);
                low_growth.noise(ichan,iamp) = noise_floor(cur_idx,iamp,ichan);
            end
            
            % Will be used for weights
            low_growth.trials(ichan,iamp) = trials_needed;

            % Trial count for scaling point size
            growth_func_trials(ichan,iamp) = cur_idx;
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
        cur_y = low_growth.mean(ichan,:);
        cur_weights = low_growth.trials(ichan,:);

        if any(isnan(cur_y)), continue; end

        cur_noise_floor = median(low_growth.noise(ichan,:)); % bootstrapped OFF-OFF with trials in average based on resp_found simulation
        
        % Fit softplus
        %% 9/3 No weights nor noise floor
        [p, ~, ~, softplus,fit_ok, ~] = param_softplus(cur_y, cur_weights, reshape(amp_vec,1,[]), cur_noise_floor, 0);

        % Create fitted softplus y vector
        y_vec = softplus(p, x_vec);

        % Save x and y vec
        low_growth.x_vec(:,:,ichan) = x_vec;
        low_growth.y_vec(:,:,ichan) = y_vec;

        % Find and assign 0 crossing threshold value
        if y_vec(1) < 0
            cross_idx = find(y_vec >= 0, 1, 'first');
            if ~isempty(cross_idx)
                cur_thresh = x_vec(cross_idx);
                low_growth.thresh_ci(ichan) = cur_thresh;
            end
        end

        % Plot model fit
        if yes_plot
            plot(x_vec,y_vec,'Color',cur_color,'LineWidth',1.5)
            hold on;

            % Scale point opacity based on trial count
            max_batch = (max_trials/10);
            alpha = 1 + ((growth_func_trials(ichan,:)- max_batch) / max_batch);
            scatter(amp_vec, cur_y, 36*1.5, cur_color, 'filled', ...
                'AlphaData', alpha, 'MarkerFaceAlpha', 'flat', ...
                'MarkerEdgeColor', cur_color)
            yline(0,'--')
            xline(cur_thresh, '--', sprintf('%.2f dB', cur_thresh), 'FontSize', 12, ...
                'LabelVerticalAlignment', 'middle', 'LabelOrientation', 'horizontal', 'Color',cur_color)
            xlabel('Stimulus Amplitude')
            if ichan == 1, ylabel('Lower CI Value'); end
            title(sprintf('%s', my_chans_name{ichan}))
            hold on;
        end

        % Save model fit parameters
        low_growth.p(ichan,1:length(p)) = p;

end

if yes_plot
    sgtitle(sprintf('%d Hz %s: Softplus fit to lower CI value',cur_freq,my_tag))
    linkaxes
end
