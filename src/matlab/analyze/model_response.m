function ex = model_response(ex,app)
%% Model the growth function using models
iamp = ex.counter.iamp;
max_trial_lim = ex.info.trials.max_trials;
mad_to_std = ex.info.signal_quality.mad_to_std;
stim_ON_2f_mean  = cellfun(@mean,ex.model.stim_ON_2f_vec(1:iamp)); % (trials x tested_amps)
stim_ON_2f_std  = cellfun(@std,ex.model.stim_ON_2f_vec(1:iamp));

per_amp_noise  = cellfun(@median,ex.model.stim_OFF_2f_vec(1:iamp)); % (trials x tested_amps)
per_amp_noise_mad = cellfun(@(x) mad(x,1)*mad_to_std, ex.model.stim_OFF_2f_vec(1:iamp));
min_amplitude_limit = ex.info.stimulus.min_amplitude_limit;

softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + 0; % Fix lower asymptote to 0

if ex.test == 1
    amplitude_vec = ex.snr_vec;
    fixed_upper_level = 20*log10(1/0.1);
    flex_lower_level = -20:2:fixed_upper_level-5;

else
    amplitude_vec = ex.model.amplitude_vec; % (1 x N_tested_amplitudes)
    fixed_upper_level = ex.info.stimulus.max_amplitude_limit;
    flex_lower_level = 0:5:fixed_upper_level-5;
end
noise_floor = ex.model.stim_OFF_2f_vec; % (trials x tested_amps)
resp_found = [ex.decision(1:iamp).resp_found];
trial_count = ex.trial_count(1:iamp);

all_noise_floor = vertcat(noise_floor{:}); % Get all noise floor measures across tested ampltudes
noise_floor_median = median(all_noise_floor,'omitnan');
noise_floor_mad = median(abs(noise_floor_median-all_noise_floor),'omitnan')*mad_to_std;

floor_criterion = noise_floor_median+noise_floor_mad;

% Check for nans
check_for_nans(noise_floor_median,'variable')
check_for_nans(noise_floor_mad,'variable')

% Sort data by tested stimulus amplitudes
[amplitude_sorted, sort_idx] = sort(amplitude_vec);
response_sorted = stim_ON_2f_mean(sort_idx);
response_std_sorted = stim_ON_2f_std(sort_idx);

per_amp_noise_sorted = per_amp_noise(sort_idx);
per_amp_noise_mad_sorted = per_amp_noise_mad(sort_idx);

resp_found_sorted = resp_found(sort_idx);
trial_count_sorted = trial_count(sort_idx);

% Add the noise floor value at 90 dB
amplitude_sorted = [min_amplitude_limit amplitude_sorted];
response_sorted = [noise_floor_median response_sorted];
response_std_sorted = [noise_floor_mad response_std_sorted];
per_amp_noise_sorted = [noise_floor_median per_amp_noise_sorted];
per_amp_noise_mad_sorted = [noise_floor_mad per_amp_noise_mad_sorted];
resp_found_sorted = [0 resp_found_sorted];
trial_count_sorted = [max_trial_lim trial_count_sorted];

% Save values to ex
ex.model.amplitude_vec_sorted = amplitude_sorted;

ex.model.response_vec_sorted = response_sorted;
ex.model.response_vec_std_sorted = response_std_sorted;

ex.model.per_amp_noise_sorted = per_amp_noise_sorted;
ex.model.per_amp_noise_mad_sorted = per_amp_noise_mad_sorted;

ex.model.resp_found_sorted = resp_found_sorted;
ex.model.trial_count_sorted = trial_count_sorted;

% Plot the data we have so far
plot_model_data_points(app.UIAxes_model_3, amplitude_sorted, per_amp_noise_sorted, ...
    per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)

title(app.UIAxes_model_3,'Current Data')
drawnow

%% Fit model
try
    if length(amplitude_sorted) > 2

        %% Gaussian Process
        % Synthetic data
        x = amplitude_sorted;                    % Levels
        y = response_sorted; % Amplitudes
        x = x(:);
        y = y(:);

        % Levels of predictions
        xs = [min(amplitude_sorted):1:max(amplitude_sorted)]';

        % GP config functions
        meanfunc = [];                    % empty: don't use a mean function
        covfunc = @covSEiso;              % Squared Exponental covariance function
        likfunc = @likGauss;              % Gaussian likelihood

        hyp = struct('mean', [], 'cov', [0.5 , 0], 'lik', log(noise_floor_mad));

        % train GP
        hyp2 = minimize(hyp, @gp, -100, @infGaussLik, meanfunc, covfunc, likfunc, x, y);

        % predict amplitudes
        [mu s2] = gp(hyp2, @infGaussLik, meanfunc, covfunc, likfunc, x, y, xs);

        %% Plot
        cla(app.UIAxes_model)
        hold(app.UIAxes_model, 'on');

        f = [mu+2*sqrt(s2); flip(mu-2*sqrt(s2))];
        fill(app.UIAxes_model, [xs; flip(xs)], f, tableau_10('grey'), 'FaceAlpha', 0.3)
        plot(app.UIAxes_model, xs, mu, 'k');

        plot_model_data_points(app.UIAxes_model, amplitude_sorted, per_amp_noise_sorted, ...
            per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)
        
        cross_idx = find(diff(sign(mu - noise_floor_median)) ~= 0, 1, 'last');
        yline(app.UIAxes_model, noise_floor_median, '--');
        thresh_val = xs(cross_idx);
        if ~isempty(thresh_val)
            ex.model.gp_threshold = [ex.model.gp_threshold  xs(cross_idx)];
            xline(app.UIAxes_model,thresh_val, '--')
        end
        xlabel(app.UIAxes_model, 'Stimulus Level')
        ylabel(app.UIAxes_model, 'Amplitude')
        title(app.UIAxes_model, 'Gaussian Process')

        %% Fit Softplus 
        signal_range = max(response_sorted) - noise_floor_median ;
        amp_range = max(amplitude_sorted) - min(amplitude_sorted);

        rise_idx = find(response_sorted > noise_floor_median  + 0.2*signal_range, 1, 'first'); % Find where the function lifts of 20% from total
        if isempty(rise_idx)
            rise_idx = round(length(amplitude_sorted)/2);
        end
        x0_init = amplitude_sorted(rise_idx);
        upper_span = max(max(amplitude_sorted) - x0_init, 0.1*amp_range);

        a_init = (max(response_sorted) - response_sorted(rise_idx)) / upper_span; % Slope of the upper arrm
        k_init = 4 / upper_span;
        p0 = [a_init,k_init,x0_init];

        lb = [0, 0.5/upper_span, min(amplitude_sorted)];   % keep k off 0
        ub = [Inf, 10/upper_span, max(amplitude_sorted)-5];  % cap knee sharpness

        p = lsqcurvefit(softplus, p0, amplitude_sorted, response_sorted, lb, ub, optimset('Display','off'));

        a1_fit = p(1);
        x0_fit = p(2);
        k_fit  = p(3);

        ex.model.x0_fit    = [ex.model.x0_fit    x0_fit];
        ex.model.a1_fit    = [ex.model.a1_fit    a1_fit];
        ex.model.k_fit     = [ex.model.k_fit     k_fit];
        ex.model.Rsquared  = [ex.model.Rsquared  R_squared];

        slope_frac = 0.05; % fraction of max slope defining "end of lower asymptote"
        x_lower_end(i_it,i_tri,ichan,isubj) = p(3) + (1/p(2))*log(slope_frac/(1-slope_frac));

        %% Plots
        cla(app.UIAxes_model_3)
        hold(app.UIAxes_model_3, 'on');
        x_plot = linspace(min(amplitude_sorted), max(amplitude_sorted), 200);
        plot(app.UIAxes_model_3, x_plot, softplus(p, x_plot), 'Color', tableau_10('blue'), 'LineWidth', 2);
        plot_model_data_points(app.UIAxes_model_3, amplitude_sorted, per_amp_noise_sorted, ...
            per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)
        xline(app.UIAxes_model_3,  x_lower_end(i_it,i_tri,ichan,isubj), '--');
        yline(app.UIAxes_model_3, noise_floor_median, '--');
        yline(app.UIAxes_model_3, 0, '--');
        ylabel(app.UIAxes_model_3, '2f Amplitude (\muV)');
        title(app.UIAxes_model_3, 'Softplus')
        hold(app.UIAxes_model_3, 'off');

        cla(app.UIAxes_thresh_est)
        plot(app.UIAxes_thresh_est, x_lower_end(i_it,i_tri,ichan,isubj), 'o-', 'Color', tableau_10('teal'), 'LineWidth', 1, 'MarkerFaceColor', tableau_10('teal'));
        xlabel(app.UIAxes_thresh_est, 'Iteration');
        ylabel(app.UIAxes_thresh_est, 'x0');
        title(app.UIAxes_thresh_est, 'Threshold Estimate');

        cla(app.UIAxes_slope_est)
        plot(app.UIAxes_slope_est, ex.model.a1_fit, 'o-', 'Color', tableau_10('orange'), 'LineWidth', 1, 'MarkerFaceColor', tableau_10('orange'));
        xlabel(app.UIAxes_slope_est, 'Iteration');
        ylabel(app.UIAxes_slope_est, 'a1');
        title(app.UIAxes_slope_est, 'Slope Estimate');
        drawnow limitrate
    end

catch ME
    fprintf('\nMessage: %s\n', ME.message);
    rethrow(ME);
end
