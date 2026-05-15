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

        

         %% Exponential
         L = noise_floor_median;  % fixed lower asymptote
         model = @(p,x) L + p(1)*p(2).^x;
         lb = [eps, eps];
         ub = [Inf, Inf];

         p = lsqcurvefit(model, [1, 1.1], x(:), y(:),lb,ub);
         mu = model(p, xs);

        % Exponential
        cla(app.UIAxes_model_2)
        hold(app.UIAxes_model_2, 'on');

        plot(app.UIAxes_model_2, xs, mu, 'k');
        plot_model_data_points(app.UIAxes_model_2, amplitude_sorted, per_amp_noise_sorted, ...
            per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)

        yline(app.UIAxes_model_2, noise_floor_median, '--');
        xlabel(app.UIAxes_model_2, 'Stimulus Level')
        ylabel(app.UIAxes_model_2, 'Amplitude')
        title(app.UIAxes_model_2, 'Exponential Model')

        %% Piecewise Linear
        % Better initial guesses
        % Use a more robust slope estimate (e.g., from the upper half of data)
        mid_idx = round(length(response_sorted)/2);
        upper_responses = response_sorted(mid_idx:end);
        upper_amps = amplitude_sorted(mid_idx:end);
        init_m = max(0.001, (mean(upper_responses) - mean(response_sorted(1:mid_idx))) / ...
            (mean(upper_amps) - mean(amplitude_sorted(1:mid_idx)))); % y2-y1 / x2 - x1

        % Set a1 initial guess above zero
        a1_fit = noise_floor_median;

        % Set bounds for the optimizer
        lb = [min(amplitude_sorted) - 20, 1e-6]; % force m > 0, and allow x0 to go slightly below the minimum observed amplitue

        ub = [max(amplitude_sorted), inf];     % x0, a1, m upper bounds
        options = optimoptions('lsqcurvefit', 'MaxIterations', 1000, ...
            'FunctionTolerance', 1e-9, 'StepTolerance', 1e-9); % Tolerance = stopping criteria for optimizer, stop when change in the cost functions is smaller than 1e-9

        % # %Clamp initial guess so it sits inside [lb, ub]
        init_x0 = median(amplitude_sorted);
        init_guess = [init_x0, init_m];

        obj_fun = @(params, x) elbow_function(x, params(1), a1_fit, params(2));
        params_fit = lsqcurvefit(obj_fun, init_guess, amplitude_sorted, response_sorted, lb, ub, options);

        x0_fit = params_fit(1);
        m_fit = params_fit(2);
        y_int = a1_fit - (m_fit*x0_fit); % Rearrangement of y = mx+b

        % After params_fit is obtained:
        y_predicted = elbow_function(amplitude_sorted, x0_fit, a1_fit, m_fit);
        SS_res = sum((response_sorted - y_predicted).^2); % Sum of squared residuals, calculate the actual value and the model's predicted value to see how much the model is wrong
        SS_tot = sum((response_sorted - mean(response_sorted)).^2); % Total sum of squares, a measure of the total variance in the data
        R_squared = 1 - SS_res / SS_tot;
        good_fit = R_squared > 0.5;  % adjust threshold as needed

        fprintf('\n Model Fit R² = %.4f\n', R_squared);

        ex.model.x0_fit = [ex.model.x0_fit x0_fit];
        ex.model.a1_fit = [ex.model.a1_fit a1_fit];
        ex.model.m_fit = [ex.model.m_fit m_fit];
        ex.model.y_int = [ex.model.y_int y_int];

        ex.model.Rsquared = [ex.model.Rsquared R_squared];

        %% Plots
        cla(app.UIAxes_model_3)
        hold(app.UIAxes_model_3, 'on');

        % Plot Model
        x_plot = linspace(min(amplitude_sorted), max(amplitude_sorted), 200);
        y_fit = elbow_function(x_plot, x0_fit, a1_fit, m_fit);
        plot(app.UIAxes_model_3, x_plot, y_fit, 'Color', tableau_10('blue'), 'LineWidth', 2);

        plot_model_data_points(app.UIAxes_model_3, amplitude_sorted, per_amp_noise_sorted, ...
            per_amp_noise_mad_sorted, trial_count_sorted, response_sorted, response_std_sorted, resp_found_sorted)


        xline(app.UIAxes_model_3, x0_fit, '--');
        yline(app.UIAxes_model_3,noise_floor_median, '--');
        ylabel(app.UIAxes_model_3, '2f Amplitude (\muV)');
        
        title(app.UIAxes_model_3,'Piecewise')
        hold(app.UIAxes_model_3, 'off');

        % Plot x0_fit on threshold axes
        cla(app.UIAxes_thresh_est)
        plot(app.UIAxes_thresh_est, ex.model.x0_fit, 'o-', 'Color', tableau_10('teal'), 'LineWidth', 1, 'MarkerFaceColor', tableau_10('teal'));
        xlabel(app.UIAxes_thresh_est, 'Iteration');
        ylabel(app.UIAxes_thresh_est, 'x0');
        title(app.UIAxes_thresh_est, 'Threshold Estimate');

        % Plot m_fit on slope axes
        cla(app.UIAxes_slope_est)
        plot(app.UIAxes_slope_est, ex.model.m_fit, 'o-', 'Color', tableau_10('orange'), 'LineWidth', 1 , 'MarkerFaceColor', tableau_10('orange'));
        xlabel(app.UIAxes_slope_est, 'Iteration');
        ylabel(app.UIAxes_slope_est, 'm');
        title(app.UIAxes_slope_est, 'Slope Estimate');

        drawnow limitrate


    end

catch ME
    fprintf('\nMessage: %s\n', ME.message);
    rethrow(ME);
end
