function ex = model_response(ex,app)
iamp = ex.counter.iamp;
max_trial_lim = ex.info.adaptive.max_trials;
mad_to_std = ex.info.analysis.mad_to_std;
stim_ON_2f_mean  = cellfun(@mean,ex.model.stim_ON_2f_vec(1:iamp)); % (trials x tested_amps)
stim_ON_2f_std  = cellfun(@std,ex.model.stim_ON_2f_vec(1:iamp));

per_amp_noise  = cellfun(@median,ex.model.stim_OFF_2f_vec(1:iamp)); % (trials x tested_amps)
per_amp_noise_mad = cellfun(@(x) mad(x,1)*mad_to_std, ex.model.stim_OFF_2f_vec(1:iamp));

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

% Add the noise floor value at 70 dB
amplitude_sorted = [80 amplitude_sorted];
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

xlim(app.UIAxes_model_3,[min(amplitude_sorted)-3 max(amplitude_sorted)+3])
ylim(app.UIAxes_model_3,[min(response_sorted)-0.01, max(response_sorted)+0.01])
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

        %% Softplus
        softplus = @(p,x) p(1)*log1p(exp(p(3)*(x - p(2))))/p(3) + p(4);
        p0 = [(max(response_sorted)-min(response_sorted))/range(amplitude_sorted), ...
            median(amplitude_sorted), 1, min(response_sorted)];
        p = lsqcurvefit(softplus, p0, amplitude_sorted, response_sorted, [], [], optimset('Display','off'));

        a1_fit = p(1);
        x0_fit = p(2);
        k_fit  = p(3);
        y_int  = p(4);
        x_10   = p(2) - log(9)/p(3);

        y_predicted = softplus(p, amplitude_sorted);
        SS_res = sum((response_sorted - y_predicted).^2);
        SS_tot = sum((response_sorted - mean(response_sorted)).^2);
        R_squared = 1 - SS_res / SS_tot;
        good_fit = R_squared > 0.5;
        fprintf('\n Model Fit R² = %.4f\n', R_squared);

        ex.model.x0_fit    = [ex.model.x0_fit    x0_fit];
        ex.model.a1_fit    = [ex.model.a1_fit    a1_fit];
        ex.model.k_fit     = [ex.model.k_fit     k_fit];
        ex.model.y_int     = [ex.model.y_int     y_int];
        ex.model.x_10      = [ex.model.x_10      x_10];
        ex.model.Rsquared  = [ex.model.Rsquared  R_squared];

        %% Plots
        cla(app.UIAxes_model_3)
        hold(app.UIAxes_model_3, 'on');
        x_plot = linspace(min(amplitude_sorted), max(amplitude_sorted), 200);
        plot(app.UIAxes_model_3, x_plot, softplus(p, x_plot), 'Color', tableau_10('blue'), 'LineWidth', 2);
        plot_model_data_points(app.UIAxes_model_3, amplitude_sorted, per_amp_noise_sorted, ...
            per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)
        xline(app.UIAxes_model_3, x_10, '--');
        yline(app.UIAxes_model_3, noise_floor_median, '--');
        ylabel(app.UIAxes_model_3, '2f Amplitude (\muV)');
        title(app.UIAxes_model_3, 'Softplus')
        hold(app.UIAxes_model_3, 'off');

        cla(app.UIAxes_thresh_est)
        plot(app.UIAxes_thresh_est, ex.model.x_10, 'o-', 'Color', tableau_10('teal'), 'LineWidth', 1, 'MarkerFaceColor', tableau_10('teal'));
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
