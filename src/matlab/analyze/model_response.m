function ex = model_response(ex,app)
iamp = ex.counter.iamp;
doub_freq_resp_mV  = ex.model.doub_freq_resp_mV; % (trials x tested_amps)
amplitude_vec = ex.model.amplitude_vec; % (1 x N_tested_amplitudes)
noise_floor = ex.model.noise_floor{iamp}; % (trials x tested_amps)
noise_floor = reshape(noise_floor, size(noise_floor,1)*size(noise_floor,2),1); % reshape to (trials*tested_amps x 1)
fixed_upper_level = ex.info.stimulus.max_amplitude_limit;
resp_found = [ex.decision.resp_found];

% Calculate noise_floor characteristics
% Select # of points in noise floor = max(N_trials_presented) across all amplitudes tested for current freq, 
% Since noise averages down to 0, only use the # of noise points that were
% actually used to calculate average for 2f calculation for a single
% amplitude
max_trials_presented = max(cellfun(@(x) size(x, 1), doub_freq_resp_mV));
select_noise_floor = noise_floor(randperm(max_trials_presented),1);
noise_floor_mean = mean(select_noise_floor);
noise_floor_std = std(select_noise_floor);

% Sort data by tested stimulus amplitudes
[amplitude_sorted, sort_idx] = sort(amplitude_vec); 
response_sorted = doub_freq_resp_mV(sort_idx);
resp_found_sorted = resp_found(sort_idx);

% Calculate mean 2f response across all trials for each stimulus amplitude condition
response_means = cellfun(@(x) mean(x,1), response_sorted, 'UniformOutput', false);
response_means = [response_means{:}];

response_vars = cellfun(@(x) var(x,1), response_sorted, 'UniformOutput', false);
response_vars = [response_vars{:}];
response_vars_inverse = 1./response_vars;

% Determine weights
weights = response_vars_inverse./sum(response_vars_inverse); %# FIGURE OUT HOW TO ADD WEIGHTS LATER...

%% Fit model
try
init_guess = [100, noise_floor_mean, 1]; % [x0 threshold, a1 noise floor, m slope]
fprintf('\nStarting model fitting')
tic()

obj_fun = @(params, x) elbow_function(x, params(1), params(2), params(3));
params_fit = lsqcurvefit(obj_fun, init_guess, amplitude_sorted, response_means);

x0_fit = params_fit(1);
a1_fit = params_fit(2);
m_fit = params_fit(3);
y_int = a1_fit - (m_fit*x0_fit);

time_elapsed = toc();
fprintf('\nFitted parameters: x0=%.3f, a1=%.3f, m=%.3f', x0_fit, a1_fit, m_fit)
fprintf('\nModel fitting computation time: %.3f s', time_elapsed)

% Generate fitted curve
x_plot = linspace(min(amplitude_sorted), max(amplitude_sorted), 200);
y_fit = elbow_function(x_plot, x0_fit, a1_fit, m_fit);

% Save values
ex.model.response_mean = response_means;
ex.model.response_vars = response_vars;
ex.model.noise_floor_mean = [ex.model.noise_floor_mean noise_floor_mean];
ex.model.noise_floor_std = [ex.model.noise_floor_std noise_floor_std];

ex.model.x0_fit = [ex.model.x0_fit x0_fit];
ex.model.a1_fit = [ex.model.a1_fit a1_fit];
ex.model.m_fit = [ex.model.m_fit m_fit];
ex.model.y_int = [ex.model.y_int y_int];

%% Plots
% Plot Model
cla(app.UIAxes_model)
plot(app.UIAxes_model, x_plot, y_fit, 'Color', tableau_10('blue'), 'LineWidth', 2);
hold(app.UIAxes_model, 'on');
plot(app.UIAxes_model, amplitude_sorted, response_means, 'o', 'MarkerSize', 12, 'MarkerFaceColor', tableau_10('orange'), 'MarkerEdgeColor', tableau_10('orange'));

% Plot individual trial dots
for i = 1:length(amplitude_sorted)
    if resp_found_sorted(i) == 1
        color = tableau_10('green');
    else
        color = tableau_10('red');
    end
    plot(app.UIAxes_model, amplitude_sorted(i), response_means(i), 'o', 'MarkerSize', 6, 'MarkerFaceColor', color, 'MarkerEdgeColor', color);
end

xline(app.UIAxes_model, x0_fit, '--', 'Color', tableau_10('grey'));
yline(app.UIAxes_model, noise_floor_mean, '--', 'Color', tableau_10('brown'), 'LineWidth', 1);
x_limits = xlim(app.UIAxes_model);
fill(app.UIAxes_model, [x_limits(1), x_limits(2), x_limits(2), x_limits(1)], ...
     [noise_floor_mean - noise_floor_std, noise_floor_mean - noise_floor_std, ...
      noise_floor_mean + noise_floor_std, noise_floor_mean + noise_floor_std], ...
     tableau_10('yellow'), 'FaceAlpha', 0.1, 'EdgeColor', 'none');
xlabel(app.UIAxes_model, 'Stimulus Amplitude (dB SPL)');
ylabel(app.UIAxes_model, '2f Amplitude (mV)');
title(app.UIAxes_model, sprintf('Elbow Fit: x0=%.3f, a1=%.3f, m=%.3f', x0_fit, a1_fit, m_fit));
grid(app.UIAxes_model, 'on');
hold(app.UIAxes_model, 'off');

% Plot x0_fit on threshold axes
cla(app.UIAxes_thresh_est)
plot(app.UIAxes_thresh_est, ex.model.x0_fit, 'Color', tableau_10('blue'), 'LineWidth', 2);
xlabel(app.UIAxes_thresh_est, 'Iteration');
ylabel(app.UIAxes_thresh_est, 'x0');
title(app.UIAxes_thresh_est, 'Threshold Estimate');
grid(app.UIAxes_thresh_est, 'on');

% Plot m_fit on slope axes
cla(app.UIAxes_slope_est)
plot(app.UIAxes_slope_est, ex.model.m_fit, 'Color', tableau_10('blue'), 'LineWidth', 2);
xlabel(app.UIAxes_slope_est, 'Iteration');
ylabel(app.UIAxes_slope_est, 'm');
title(app.UIAxes_slope_est, 'Slope Estimate');
grid(app.UIAxes_slope_est, 'on');

%% Suggest next best amplitude to test
fprintf('\nStarting Monte Carlo simulation')
tic()
 monte_carlo_slope(app, m_fit, y_int, ...
    noise_floor_mean, noise_floor_std, fixed_upper_level);
time_elapsed = toc();
fprintf('\nMonte Carlo computation time: %.3f s', time_elapsed)

catch ME
    fprintf('Message: %s\n', ME.message);
    rethrow(ME);
end