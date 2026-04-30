function ex = model_response(ex,app)
iamp = ex.counter.iamp;
doub_freq_stim_ON_mean  = cellfun(@mean,ex.model.doub_freq_stim_ON_vec); % (trials x tested_amps)
if ex.test == 1
    amplitude_vec = ex.snr_vec;
    fixed_upper_level = 20*log10(1/0.1);
    flex_lower_level = -20:2:fixed_upper_level-5;
    
else
    amplitude_vec = ex.model.amplitude_vec; % (1 x N_tested_amplitudes)
    fixed_upper_level = ex.info.stimulus.max_amplitude_limit;
    flex_lower_level = 0:5:fixed_upper_level-5;
end
noise_floor = ex.model.noise_floor; % (trials x tested_amps)
resp_found = [ex.decision(1:iamp).resp_found];
trial_count = ex.trial_count(1:iamp);

all_noise_floor = vertcat(noise_floor{:}); % Get all noise floor measures across tested ampltudes
noise_floor_median = median(all_noise_floor,'omitnan');
noise_floor_mad = median(abs(noise_floor_median-all_noise_floor),'omitnan')*1.4826;

% Check for nans
check_for_nans(noise_floor_median,'variable')
check_for_nans(noise_floor_mad,'variable')

% Sort data by tested stimulus amplitudes
[amplitude_sorted, sort_idx] = sort(amplitude_vec);
response_sorted = doub_freq_stim_ON_mean(sort_idx);
resp_found_sorted = resp_found(sort_idx);
trial_count_sorted = trial_count(sort_idx);

% Save values to ex
ex.model.amplitude_vec_sorted = amplitude_sorted;
ex.model.response_vec_sorted = response_sorted;
ex.model.resp_found_sorted = resp_found_sorted;
ex.model.trial_count_sorted = trial_count_sorted;

%% Fit model
try
    % Better initial guesses
    % Use a more robust slope estimate (e.g., from the upper half of data)
    mid_idx = round(length(response_sorted)/2);
    upper_responses = response_sorted(mid_idx:end);
    upper_amps = amplitude_sorted(mid_idx:end);
    init_m = max(0.001, (mean(upper_responses) - mean(response_sorted(1:mid_idx))) / ...
        (mean(upper_amps) - mean(amplitude_sorted(1:mid_idx)))); % y2-y1 / x2 - x1

    % Set a1 initial guess above zero
    a1_fit = noise_floor_median;

    init_guess = [median(amplitude_sorted), init_m]; % x0, m ; a1 is fixed

    % Set bounds for the optimizer
    lb = [min(amplitude_sorted) - 20, 1e-6]; % force m > 0, and allow x0 to go slightly below the minimum observed amplitue

    ub = [max(amplitude_sorted), inf];     % x0, a1, m upper bounds
    options = optimoptions('lsqcurvefit', 'MaxIterations', 1000, ...
        'FunctionTolerance', 1e-9, 'StepTolerance', 1e-9); % Tolerance = stopping criteria for optimizer, stop when change in the cost functions is smaller than 1e-9

    fprintf('\nStarting model fitting\n')
    tic()

    obj_fun = @(params, x) elbow_function(x, params(1), a1_fit, params(2));
    params_fit = lsqcurvefit(obj_fun, init_guess, amplitude_sorted, response_sorted, lb, ub, options);

    x0_fit = params_fit(1);
    m_fit = params_fit(2);
    y_int = a1_fit - (m_fit*x0_fit); % Rearrangement of y = mx+b

    time_elapsed = toc();
    fprintf('\nFitted parameters: x0 = %.3f, a1 = %.3f, m = %.3f\n', x0_fit, a1_fit, m_fit)
    fprintf('\nModel fitting computation time: %.3f s\n', time_elapsed)

    % After params_fit is obtained:
    y_predicted = elbow_function(amplitude_sorted, x0_fit, a1_fit, m_fit);
    SS_res = sum((response_sorted - y_predicted).^2); % Sum of squared residuals, calculate the actual value and the model's predicted value to see how much the model is wrong
    SS_tot = sum((response_sorted - mean(response_sorted)).^2); % Total sum of squares, a measure of the total variance in the data
    R_squared = 1 - SS_res / SS_tot; 
    good_fit = R_squared > 0.5;  % adjust threshold as needed

    fprintf('\n Model Fit R² = %.4f\n', R_squared);
    
    %% Plots
    cla(app.UIAxes_model)
    hold(app.UIAxes_model, 'on');

    if good_fit
        % Save values
        ex.model.x0_fit = [ex.model.x0_fit x0_fit];
        ex.model.a1_fit = [ex.model.a1_fit a1_fit];
        ex.model.m_fit = [ex.model.m_fit m_fit];
        ex.model.y_int = [ex.model.y_int y_int];

        ex.model.Rsquared = [ex.model.Rsquared R_squared];

        ex.model.amplitude_vec_sorted = amplitude_sorted;
        ex.model.response_vec_sorted = response_sorted;
        ex.model.resp_found_sorted = resp_found_sorted;
        ex.model.trial_count_sorted = trial_count_sorted;

        % Plot Model
        x_plot = linspace(min(amplitude_sorted), max(amplitude_sorted), 200);
        y_fit = elbow_function(x_plot, x0_fit, a1_fit, m_fit);
        plot(app.UIAxes_model, x_plot, y_fit, 'Color', tableau_10('blue'), 'LineWidth', 2);
    
    else % Calculate linear regression instead
        params_fit = polyfit(amplitude_sorted, response_sorted, 1); % Fit a one degree (i.e., line) polynomial to the data
        m_fit = params_fit(1);
        y_int = params_fit(2);

        y_predicted = polyval(params_fit, amplitude_sorted); % polyval outputs Y values according to the input x values and the parameters
        SS_res = sum((response_sorted - y_predicted).^2);
        SS_tot = sum((response_sorted - mean(response_sorted)).^2);
        R_squared = 1 - SS_res / SS_tot;
        
        ex.model.x0_fit = [ex.model.x0_fit NaN];
        ex.model.a1_fit = [ex.model.a1_fit NaN];
        ex.model.m_fit = [ex.model.m_fit m_fit];
        ex.model.y_int = [ex.model.y_int y_int];

        ex.model.Rsquared = [ex.model.Rsquared R_squared];
        % Plot model
        x_plot = linspace(min(amplitude_sorted), max(amplitude_sorted), 200);
        y_fit = polyval(params_fit, x_plot);
        plot(app.UIAxes_model, x_plot, y_fit, 'Color', tableau_10('blue'), 'LineWidth', 2);
    end

    % Plot individual trial dots
    for i = 1:length(amplitude_sorted)
        if resp_found_sorted(i) == 1
            color = tableau_10('green');
            
        else
            color = tableau_10('red');
        end
        plot(app.UIAxes_model, amplitude_sorted(i), response_sorted(i), 'o', 'MarkerSize', 6+trial_count_sorted(i)/max(trial_count_sorted), 'MarkerFaceColor', color, 'MarkerEdgeColor', color);
    end

    if good_fit
        xline(app.UIAxes_model, x0_fit, '--', 'Color', tableau_10('grey'),'LineWidth',2);
    end    
    yline(app.UIAxes_model,noise_floor_median, 'k-','LineWidth',2);
    xlims = xlim(app.UIAxes_model);
    x_fill = [xlims(1), xlims(2), xlims(2), xlims(1)];
    y_fill = [noise_floor_median - 3*noise_floor_mad, noise_floor_median - 3*noise_floor_mad, ...
        noise_floor_median + 3*noise_floor_mad, noise_floor_median + 3*noise_floor_mad];
    fill(app.UIAxes_model,x_fill, y_fill, tableau_10('purple'), 'FaceAlpha', 0.2, 'EdgeColor', 'none');    xlabel(app.UIAxes_model, 'Stimulus Amplitude (dB SPL)');
    ylabel(app.UIAxes_model, '2f Amplitude (\muV)');
    if good_fit
        title(app.UIAxes_model, sprintf('Elbow Fit: x0=%.3f, a1=%.3f, m=%.3f (R²=%.4f)', x0_fit, a1_fit, m_fit, R_squared));
    else
        title(app.UIAxes_model, sprintf('Linear Fit: m=%.3f, b=%.3f (R²=%.4f)', m_fit, y_int, R_squared));
    end
    grid(app.UIAxes_model,  'on');
    hold(app.UIAxes_model, 'off');

    % Plot x0_fit on threshold axes
    cla(app.UIAxes_thresh_est)
    plot(app.UIAxes_thresh_est, ex.model.x0_fit, 'o-', 'Color', tableau_10('teal'), 'LineWidth', 1.5);
    xlabel(app.UIAxes_thresh_est, 'Iteration');
    ylabel(app.UIAxes_thresh_est, 'x0');
    title(app.UIAxes_thresh_est, 'Threshold Estimate');
    grid(app.UIAxes_thresh_est, 'on');

    % Plot m_fit on slope axes
    cla(app.UIAxes_slope_est)
    plot(app.UIAxes_slope_est, ex.model.m_fit, 'o-', 'Color', tableau_10('orange'), 'LineWidth', 1.5);
    xlabel(app.UIAxes_slope_est, 'Iteration');
    ylabel(app.UIAxes_slope_est, 'm');
    title(app.UIAxes_slope_est, 'Slope Estimate');
    grid(app.UIAxes_slope_est, 'on');

    drawnow limitrate

    %% Suggest next best amplitude to test
    fprintf('\nStarting Monte Carlo simulation')
    tic()
    monte_carlo_slope(app, m_fit, y_int, ...
        noise_floor_median, noise_floor_mad, fixed_upper_level, flex_lower_level);
    time_elapsed = toc();
    fprintf('\nMonte Carlo computation time: %.3f s\n', time_elapsed)

catch ME
    fprintf('\nMessage: %s\n', ME.message);
    rethrow(ME);
end