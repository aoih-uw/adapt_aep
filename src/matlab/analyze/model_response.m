function ex = model_response(ex,app)
iamp = ex.counter.iamp;
doub_freq_diff_mean  = cell2mat(ex.model.doub_freq_diff_mean); % (trials x tested_amps)
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
mad_criteria = ex.info.analysis.mad_criteria;
trial_count = ex.trial_count(1:iamp);


% Calculate noise_floor characteristics
noise_floor_medians = cellfun(@median, noise_floor);
noise_floor_mads = cellfun(@mad, noise_floor);
thres_criterias = noise_floor_medians + noise_floor_mads*1.4826*mad_criteria;
[~,idx] = min(thres_criterias);
select_noise_floor = noise_floor{idx};
noise_floor_median = median(select_noise_floor);
noise_floor_mad = mad(select_noise_floor);

% Sort data by tested stimulus amplitudes
[amplitude_sorted, sort_idx] = sort(amplitude_vec);
response_sorted = doub_freq_diff_mean(sort_idx);
resp_found_sorted = resp_found(sort_idx);

%% Fit model
try
    if ex.test == 1
        init_guess = [0, noise_floor_median, 1];
    else
        init_guess = [100, noise_floor_median, 1]; % [x0 threshold, a1 noise floor, m slope]
    end
    fprintf('\nStarting model fitting\n')
    tic()

    obj_fun = @(params, x) elbow_function(x, params(1), params(2), params(3));
    params_fit = lsqcurvefit(obj_fun, init_guess, amplitude_sorted, response_sorted);

    x0_fit = params_fit(1);
    a1_fit = params_fit(2);
    m_fit = params_fit(3);
    y_int = a1_fit - (m_fit*x0_fit);

    time_elapsed = toc();
    fprintf('\nFitted parameters: x0 = %.3f, a1 = %.3f, m = %.3f\n', x0_fit, a1_fit, m_fit)
    fprintf('\nModel fitting computation time: %.3f s\n', time_elapsed)

    % Generate fitted curve
    x_plot = linspace(min(amplitude_sorted), max(amplitude_sorted), 200);
    y_fit = elbow_function(x_plot, x0_fit, a1_fit, m_fit);

    % Save values
    ex.model.x0_fit = [ex.model.x0_fit x0_fit];
    ex.model.a1_fit = [ex.model.a1_fit a1_fit];
    ex.model.m_fit = [ex.model.m_fit m_fit];
    ex.model.y_int = [ex.model.y_int y_int];

    %% Plots
    cla(app.UIAxes_model)

    % Noise floor shaded region
    xlims = xlim(app.UIAxes_model);
    x_fill = [xlims(1), xlims(2), xlims(2), xlims(1)];
    y_fill = [noise_floor_median - mad_criteria*1.4826*noise_floor_mad, noise_floor_median - mad_criteria*1.4826*noise_floor_mad, ...
        noise_floor_median + mad_criteria*1.4826*noise_floor_mad, noise_floor_median + mad_criteria*1.4826*noise_floor_mad];
    fill(app.UIAxes_model,x_fill, y_fill, tableau_10('purple'), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    
    % Plot Model
    plot(app.UIAxes_model, x_plot, y_fit, 'Color', tableau_10('blue'), 'LineWidth', 2);
    hold(app.UIAxes_model, 'on');

    % Plot individual trial dots
    for i = 1:length(amplitude_sorted)
        if resp_found_sorted(i) == 1
            color = tableau_10('green');
        else
            color = tableau_10('red');
        end
        plot(app.UIAxes_model, amplitude_sorted(i), response_sorted(i), 'o', 'MarkerSize', 6+trial_count(i)/max(trial_count), 'MarkerFaceColor', color, 'MarkerEdgeColor', color);
    end

    xline(app.UIAxes_model, x0_fit, '--', 'Color', tableau_10('grey'),'LineWidth',2);
    yline(app.UIAxes_model, noise_floor_median, '--', 'Color', tableau_10('brown'), 'LineWidth', 1);
    yline(app.UIAxes_model,noise_floor_median, 'k--');
    xlabel(app.UIAxes_model, 'Stimulus Amplitude (dB SPL)');
    ylabel(app.UIAxes_model, '2f Amplitude (mV)');
    title(app.UIAxes_model, sprintf('Elbow Fit: x0=%.3f, a1=%.3f, m=%.3f', x0_fit, a1_fit, m_fit));
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

    %% Suggest next best amplitude to test
    fprintf('\nStarting Monte Carlo simulation')
    tic()
    monte_carlo_slope(app, m_fit, y_int, ...
        noise_floor_median, noise_floor_mad, fixed_upper_level, flex_lower_level);
    time_elapsed = toc();
    fprintf('\nMonte Carlo computation time: %.3f s\n', time_elapsed)

catch ME
    fprintf('Message: %s\n', ME.message);
    rethrow(ME);
end