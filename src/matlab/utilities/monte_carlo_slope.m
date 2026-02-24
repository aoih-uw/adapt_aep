function  monte_carlo_slope(app, slope, y_int, noise_mu, noise_sigma, fixed_upper_level, flex_lower_level)
% slope = "ground truth" slope, but actually is the last best fit

nreps = 500;
nreps_measures = 2;

est_slope = zeros(length(flex_lower_level), nreps);
err_slope = zeros(length(flex_lower_level), nreps);

for irep = 1:nreps
    groundtruth_slope = slope+randn*slope; % generate random distribution, generate a distribution of possible slopes from my previous data
    groundtruth_func = @(L) max(groundtruth_slope*L+y_int,0);
    for ilev = 1:length(flex_lower_level)
        % make a measurement at the two levels
        upper_measure = groundtruth_func(fixed_upper_level) + (randn(1,nreps_measures)*noise_sigma+noise_mu); % signal + noise
        lower_measure = groundtruth_func(flex_lower_level(ilev)) + (randn(1,nreps_measures)*noise_sigma+noise_mu); % at lower levels, the noise is a much larger fraction of the signal
        
        % linear fit to the measures
        prefit_x = [fixed_upper_level*ones(1,nreps_measures), flex_lower_level(ilev)*ones(1,nreps_measures)];
        prefit_y = [upper_measure, lower_measure];
        p = polyfit(prefit_x, prefit_y, 1);
        est_slope(ilev, irep) = p(1);
        err_slope(ilev, irep) = p(1) - groundtruth_slope;
    end
end

fig = figure();
rms_slope_err = rms(err_slope');
plot(flex_lower_level, rms_slope_err,'o-', 'LineWidth',1.5, 'Color',tableau_10('pink'));
title('RMS Error from the Groundtruth');
xlabel('Sampled Level (dB SPL)');
ylabel('RMS Error (\muV)')
uiwait(fig);