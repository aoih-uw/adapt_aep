function [low_growth, fit_quality] = ...
    fit_low_CI_model(amp_vec, lower_ci_vec, resp_stable, my_params, ifreq,...
    trials_per_block, max_trials, my_chans_name, cur_freq, my_tag, yes_plot)
%% Fits a softplus growth function to low CI bootstrap values as a function of stimulus amplitude
% This is how the aep threshold is determined
% Compares the full dataset fit to a simulated lower asymptote to mimic
% a live adaptive aep experiment

%% Assign variables
my_reso = 2000;
OFF_2f = my_params.OFF_2f;
phase_vec = my_params.phase_vec;
x_vec = linspace(min(amp_vec), max(amp_vec), my_reso);
p_chan = NaN(size(my_chans_name,2),4);
stable_n = [];

%% Preallocate Variables
% Low CI growth function matricies
low_growth.all.low_CI = NaN(length(my_chans_name),length(amp_vec));
low_growth.sim.low_CI = NaN(length(my_chans_name),length(amp_vec)); % Simulated lower asymptote

% Model output
low_growth.all.thresh_ci = NaN(length(my_chans_name),1);
low_growth.all.p = NaN(length(my_chans_name),4);
low_growth.sim.thresh_ci = NaN(length(my_chans_name),1);
low_growth.sim.p = NaN(length(my_chans_name),4);

%% Lower CI based growth function (SOFTPLUS)
% Generate a growth function vector simulating live experiment with uneven trial counts based on bootstrap decisions
for iamp = 1:length(amp_vec)
    for ichan = 1:length(my_chans_name)
        trials_needed = resp_stable(ichan,iamp,end,end); % Trials needed to find a response
        % Build the growth function vectors
        cur_idx = trials_needed/trials_per_block;
        if isnan(cur_idx) % Get the mean and sem of the last measured batch
            keyboard
            cur_idx = size(lower_ci_vec,1);  % no response found: all batches used
            low_growth.all.low_CI(ichan,iamp) = lower_ci_vec(end,iamp,ichan);
        else % Get the valid resp_found idx and extract its mean/sem
            low_growth.all.low_CI(ichan,iamp) = lower_ci_vec(cur_idx,iamp,ichan);
        end

        % Trial count for scaling point size
        growth_func_trials(ichan,iamp) = cur_idx;
    end
end

%% Find the bootstrap threshold and identify how many trials we have to work with to build the lower asymptote
% Identify amps and channels a response was found for current frequency
found_resp_mask = resp_stable(:,:,end,end) < max_trials;

% Which was the lowest amplitude where a response was found across all channels?
[~,thresh_col] = max(found_resp_mask, [],2);
idx_col = 2:3; % Valid electrode channels (exclude forebrain and EKG)

if min(thresh_col(idx_col)) == 1
    % no threshold was found at the most sensitive channel so skip
else
    % Identify the most sensitive channel
    [~, idx_sens_chan] = min(thresh_col(idx_col));
    most_sens_chan = idx_col(idx_sens_chan);
    avail_trials = resp_stable(most_sens_chan,:,end,end);

    % Identify the highest amplitude where no response was found, this
    % amplitude will count towards our available trials to choose from
    % Since in the live adaptive protocol, you would test at lower and
    % lower amplitudes until you have one amplitude that took up to the max
    % trial limit and you did not see a response. We want to simulate this
    first_no_resp = find(avail_trials == max_trials,1,'last');
    select_amp_vec = amp_vec(first_no_resp:end);
    if any(avail_trials(1:first_no_resp-1) ~= max_trials) % There should be only max_trials listed
        keyboard
    end
    % Identify the number of trials we are able to simulate the lower
    % asymptote with
    avail_trials = avail_trials(first_no_resp:end);
    amps_to_sim = amp_vec(1:first_no_resp-1); % There were no responses at these frequencies

    % Select stim OFF trials based on amplitudes where we found a response AND the first amplitude where no response was found
    % and ensure equal phases (it shouldn't really matter because it is noise though...)
    for ichan = 1:length(my_chans_name)
        avail_pos = [];
        avail_neg = [];
        for iamp = 1:numel(avail_trials)
            cur_trial_N = avail_trials(iamp);
            amp_idx = find(select_amp_vec(iamp) == amp_vec);
            cur_phase_vec = phase_vec(:,1,amp_idx,1,ichan,ifreq);

            % Divide available trials by phase
            cur_trials_idx = find(cur_phase_vec == 1,cur_trial_N/2,'first');
            avail_pos = [avail_pos; OFF_2f(cur_trials_idx,amp_idx,1,ichan,ifreq)];
            cur_trials_idx = find(cur_phase_vec == -1,cur_trial_N/2,'first');
            avail_neg = [avail_neg; OFF_2f(cur_trials_idx,amp_idx,1,ichan,ifreq)];

        end

        %% Calculate bootstrapped distribution for each simulated lower asymptote data point
        % Calculate number of amplitudes you want to simulate, and how many
        % trials you can assign for each with the maximum number of trials
        % you can assign to each amplitude given all available trials
        % You want to maximize the number of trials you can include in the
        % average

        % Make sure enough trials are available for simulating the last amps
        length(amps_to_sim);
        if length(avail_pos) ~= length(avail_neg)
            keyboard
        end
        % How many trials can we give to each amplitude we want to simulate?
        N_trials_each = floor(length(avail_pos)/length(amps_to_sim));

        % Randomize order of available trials
        rand_idx = randperm(length(avail_pos));
        avail_pos = avail_pos(rand_idx);
        rand_idx = randperm(length(avail_neg));
        avail_neg = avail_neg(rand_idx);
        idx = 1;

        % Build simulated data points for amps that had no response (after the first no response)
        % Since this is supposed to imitate the ON-OFF bootstrap procedure,
        % split half of the available trials for this amplitude as ON and
        % then use the other for OFF even though technically they are OFF
        for iamp = 1:numel(amps_to_sim)
            p = avail_pos(idx:idx+N_trials_each-1);
            n = avail_neg(idx:idx+N_trials_each-1);
            balanced_set = reshape([p(:) n(:)].', [], 1); % Reshape so that the balanced set is ordered +-+-...
            length_set = length(balanced_set);
            [~,low_CI,~] = calculate_bootstrap(5000,...
                balanced_set(1:(length_set/2))', balanced_set(((length_set/2)+1):end)',99);

            low_growth.sim.low_CI(ichan,iamp) = low_CI;
            idx = idx+N_trials_each;
        end

        % Now add in real data at amplitudes we do not need to simulate to sim vector
        for iamp = (length(amps_to_sim)+1):length(amp_vec)
            low_growth.sim.low_CI(ichan,iamp) = low_growth.all.low_CI(ichan,iamp);
        end
    end
end

if yes_plot
    figure; tiledlayout(1,length(my_chans_name),'TileSpacing','tight','Padding','tight');
end

%% Fit softplus
% Preallocate fit quality variables
n_chan = length(my_chans_name);
fit_quality.all.resnorm  = NaN(n_chan,1);
fit_quality.all.exitflag = NaN(n_chan,1);
fit_quality.all.pinned   = NaN(n_chan,4);

fit_quality.sim.resnorm  = NaN(n_chan,1);
fit_quality.sim.exitflag = NaN(n_chan,1);
fit_quality.sim.pinned   = NaN(n_chan,4);

% Loop through data
for ichan = 1:length(my_chans_name)
    % Reset threshold variables so they don't get passed over from channel to channel
    cur_thresh = NaN;
    cur_thresh_sim = NaN;
    if yes_plot
        nexttile
    end
    cur_color = select_chan_color(ichan);

    % Assign the y values you want to fit the model to
    cur_y = low_growth.all.low_CI(ichan,:);
    cur_y_sim = low_growth.sim.low_CI(ichan,:);

    % Identify how similar the simulated vs. full lower asymptote means are
    % Compare means since this is noise, calculate percentage difference in
    % the lower asymptote mean values
    all_mean = mean(cur_y(1:length(amps_to_sim)));
    sim_mean = mean(cur_y_sim(1:length(amps_to_sim)));
    low_growth.sim.mean_pct_diff(ichan) = ((all_mean - sim_mean) / all_mean)* 100;

    % Check for NaNs
    if any(isnan(cur_y)), continue; end

    %% Fit all data softplus
    [p, ~, ~, softplus, fq] = param_softplus(cur_y, [], reshape(amp_vec,1,[]), [], 0);

    %% Store fit quality information
    fit_quality.all.resnorm(ichan)  = fq.resnorm;
    fit_quality.all.exitflag(ichan) = fq.exitflag;
    fit_quality.all.pinned(ichan,:) = fq.pinned;
    low_growth.all.p(ichan,:) = p;

    % Create fitted softplus y vector
    y_vec = softplus(p, x_vec);

    % Find and assign 0 crossing threshold value
    if y_vec(1) < 0
        cross_idx = find(y_vec >= 0, 1, 'first');
        if ~isempty(cross_idx)
            cur_thresh = x_vec(cross_idx);
            low_growth.all.thresh_ci(ichan) = cur_thresh;
        end
    end

    %% Fit sim data softplus
    if ~any(isnan(cur_y_sim))
        [p, ~, ~, softplus, fq] = param_softplus(cur_y_sim, [], reshape(amp_vec,1,[]), [], 0);

        %% Save fit quality information
        fit_quality.sim.resnorm(ichan)  = fq.resnorm;
        fit_quality.sim.exitflag(ichan) = fq.exitflag;
        fit_quality.sim.pinned(ichan,:) = fq.pinned;
        low_growth.sim.p(ichan,:) = p;

        % Create fitted softplus y vector
        y_vec_sim = softplus(p, x_vec);

        % Find and assign 0 crossing threshold value
        if y_vec_sim(1) < 0
            cross_idx = find(y_vec_sim >= 0, 1, 'first');
            if ~isempty(cross_idx)
                cur_thresh_sim = x_vec(cross_idx);
                low_growth.sim.thresh_ci(ichan) = cur_thresh_sim;
            end
        end
    end

    %% Plot model fit
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
        xline(cur_thresh_sim, '--', 'Color',cur_color) % Indicate the simulation threshold
        xlabel('Stimulus Amplitude')
        if ichan == 1, ylabel('Lower CI Value'); end
        title(sprintf('%s', my_chans_name{ichan}))
        hold on;
    end

end

if yes_plot
    sgtitle(sprintf('%d Hz %s: Softplus fit to lower CI value',cur_freq,my_tag))
    linkaxes
end
