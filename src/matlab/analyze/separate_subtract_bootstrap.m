function ex = separate_subtract_bootstrap(ex,app)
%% Separate STIM ON (stim_ON) and STIM OFF (stim_OFF) periods and calculate differences
% Assign variables
fs = ex.info.recording.sampling_rate_hz;
current_amplitude = ex.info.stimulus.amplitude_spl;
kept_trials_filtered = ex.kept.trials_filtered;
N_valid_trials = size(ex.kept.trials_filtered,1);
kept_jitter = ex.kept.jitter;
max_trials = ex.info.trials.max_trials;

% Sample variables
latency_samples = ex.info.recording.latency_samples;
period_length_samples = length(ex.info.stimulus.waveform);
ramp_duration_ms = ex.info.stimulus.ramp_duration_ms;
ramp_duration_samples = ceil(ramp_duration_ms/1000*fs);

% Median absolute deviation variables
mad_to_std = ex.info.signal_quality.mad_to_std;

% Gate variables
min_trials_for_analysis = ex.info.analysis.min_trials_for_analysis;
run_bootstrap = 0;
gate_type = 0;

% Permutation Variables
n_permutations = 1000;
my_prctile = 99.95;%

% Assign target frequency
if ex.test == 1
    freq_2f_hz  = ex.info.stimulus.frequency_hz;
else
    freq_2f_hz  = ex.info.stimulus.frequency_hz*2;
end
range_2f_hz = ex.info.stimulus.range_2f_hz;

%% Clear axes
cla(app.UIAxes_boot)
% cla(app.UIAxes_perm)
cla(app.UIAxes_gate)

% Extract Stim ON and OFF Periods
[stim_ON , stim_OFF] = extract_stim_ON_OFF(latency_samples, period_length_samples, kept_jitter, ramp_duration_samples, kept_trials_filtered);

%% See if noise has averaged down enough to do analysis
if isnan(ex.noise.starting_rms)
    starting_rms = rms(mean(stim_OFF));
    ex.noise.starting_rms = starting_rms;
end
starting_rms = ex.noise.starting_rms;
current_rms = rms(mean(stim_OFF));
rms_ratio = current_rms/starting_rms;
fprintf('\nRMS ratio: %1.2f\nTrials in average: %1.0f\n',rms_ratio,N_valid_trials)

%% Calculate FFTs
% Preallocate
N_stim_OFF = zeros(size(stim_OFF,1),1);
N_stim_ON = zeros(size(stim_OFF,1),1);

% Nyquist Shannon Theorem 
% You can only represent frequencies up to half of the sampling rate
freq_vec_stim_OFF = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1);
freq_vec_stim_ON = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1);

fft_vals_stim_OFF = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1);
fft_vals_stim_ON = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1);

% Calculate FFTs
for itrial = 1:size(stim_OFF,1)
    [N_stim_OFF(itrial), freq_vec_stim_OFF(itrial,:), fft_vals_stim_OFF(itrial,:)] ...
        = calc_fft(stim_OFF(itrial,:),fs);
    [N_stim_ON(itrial), freq_vec_stim_ON(itrial,:), fft_vals_stim_ON(itrial,:)] ...
        = calc_fft(stim_ON(itrial,:),fs);
end

% Just pick one freq_vec for ease
freq_vec = freq_vec_stim_ON(1,:);

%% Extract Stim ON 2f bins
[stim_ON_2f_vec, ~] = ...
    find_fft_bins(freq_2f_hz, range_2f_hz, fft_vals_stim_ON, freq_vec);

%% Extract Stim OFF 2f bins (i.e., noise floor)
% Get the magnitude value at 2f in the stim OFF period to compare to stim ON period for the model
    [stim_OFF_2f_vec, ~] = ...
    find_fft_bins(freq_2f_hz, range_2f_hz, fft_vals_stim_OFF, freq_vec);

%% Calculate DIFF: Subtract ON - OFF for bootstrap
diffs = fft_vals_stim_ON - fft_vals_stim_OFF; % Subtract across full freq_vec range
[diff_2f_vec, ~] = ...
    find_fft_bins(freq_2f_hz, range_2f_hz, diffs, freq_vec);

%% Calculate mean diff 2f magnitude to compare to other peaks in diff
diff_2f_mean = mean(diff_2f_vec); % Collapse 2f diff bin means across trials

% Calculate distribution of values at non 2f bins for comparison
other_freq_diff_mean_distribution = ...
    calculate_fft_noise_floor(freq_2f_hz/2, range_2f_hz, mean(diffs), freq_vec,1); % freq_2f_hz/2 is used so we can also account for stimulus artefact
top_percent_peak_num = ceil(length(other_freq_diff_mean_distribution)*0.05); % Compare to top 5% of the noise floor distribution
max_vals = maxk(other_freq_diff_mean_distribution,top_percent_peak_num);
within_diff_criteria = median(max_vals)+mad(max_vals,1)*3*mad_to_std;

%% Assign values to ex.block
ex.fft.diffs = diffs;
ex.fft.stim_ON = fft_vals_stim_ON;
ex.fft.stim_OFF = fft_vals_stim_OFF;
ex.fft.freq_vec = freq_vec;
ex.fft.stim_ON_2f_vec = stim_ON_2f_vec;
ex.fft.stim_OFF_2f_vec = stim_OFF_2f_vec;
ex.fft.diff_2f_vec = diff_2f_vec;

%% Plotting
f_diffs = freq_vec;
mean_diffs = mean(diffs,1); % Collapse diff ffts across trials
s_diffs = std(diffs, 0, 1);

% Plot on app axes
reset(app.UIAxes_diff_fft);
fill(app.UIAxes_diff_fft, [f_diffs fliplr(f_diffs)], [mean_diffs+s_diffs fliplr(mean_diffs-s_diffs)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold(app.UIAxes_diff_fft, 'on');
plot(app.UIAxes_diff_fft, f_diffs, mean_diffs, 'Color', tableau_10('blue'), 'LineWidth', 1.5);

% X-limits: symmetric window around 2f
half_width = freq_2f_hz / 2;          % tweak: 0.5*2f gives an octave on each side
xl = [freq_2f_hz - half_width, freq_2f_hz + half_width];
xlim(app.UIAxes_diff_fft, xl);

% Y-limits: focus on the 2f bin
in_2f = f_diffs >= (freq_2f_hz - range_2f_hz) & f_diffs <= (freq_2f_hz + range_2f_hz);
y_lo = min(mean_diffs(in_2f) - s_diffs(in_2f));
y_hi = max(mean_diffs(in_2f) + s_diffs(in_2f));
pad  = 0.15 * (y_hi - y_lo);
ylim(app.UIAxes_diff_fft, [y_lo - pad, y_hi + pad]);

% Add labels
title(app.UIAxes_diff_fft, 'Difference FFT');
yline(app.UIAxes_diff_fft, 0, '--');
xline(app.UIAxes_diff_fft, freq_2f_hz,'--')
xlabel(app.UIAxes_diff_fft,'Frequency (Hz)')
ylabel(app.UIAxes_diff_fft,'Amplitude (\muV)')
hold(app.UIAxes_diff_fft, 'off');

drawnow

%% Decision Logic
% Run bootstrap if...
% 1. When mean difference FFT @2f bin is x MAD greater than the median of the 5% greatest peaks at the other frequency bins in the difference fft
% 2. If RMS of signal has reduced  (i.e., signal quality has increased by x%) AND the mean(stim ON 2f bin) >
% 2 MAD above the median(stim OFF 2f bin) AND we have at least N_trials available for analysis
% 3. Or if we have hit the trial limit

%#% This gating function necesetates a large effect size (i.e., high SNR)
% or have enough trials in order to do Bootstrapping which is necessary...
if diff_2f_mean > within_diff_criteria 
    run_bootstrap = 1;
    gate_type = 1;
elseif rms_ratio <= 0.8 && N_valid_trials > min_trials_for_analysis
    run_bootstrap = 1;
    gate_type = 2;
elseif N_valid_trials >= max_trials
    run_bootstrap = 1;
    gate_type = 3;
end

% Run the bootstrap
if run_bootstrap
    ex.counter.iboot = ex.counter.iboot + 1;
    iboot = ex.counter.iboot;

    [bootstat, lower_CI, upper_CI] = calculate_bootstrap(ex, diff_2f_vec);
    fprintf('\nBootstrapping CI range: [ %.3f , %.3f ]',lower_CI, upper_CI)
    
    % Save to boot
    ex.bootstrap(iboot).bootstat = bootstat;
    ex.bootstrap(iboot).gate_type = gate_type;
    ex.bootstrap(iboot).lower_CI = lower_CI;
    ex.bootstrap(iboot).upper_CI = upper_CI;

    % Plot bootstrapped distribution on app axes
    reset(app.UIAxes_boot)
    histogram(app.UIAxes_boot, bootstat, 'FaceColor', tableau_10('blue'));
    hold(app.UIAxes_boot, 'on');
    xline(app.UIAxes_boot, 0, '--');
    xline(app.UIAxes_boot, lower_CI,  'LineStyle', '--', 'Color', tableau_10('red'), 'LineWidth', 1.5)
    xline(app.UIAxes_boot, upper_CI,  'LineStyle', '--', 'Color', tableau_10('red'), 'LineWidth', 1.5)
    xlim(app.UIAxes_boot, 'auto');
    cur_xlim = xlim(app.UIAxes_boot);
    xlim(app.UIAxes_boot, [-max(abs(cur_xlim)), max(abs(cur_xlim))]);
    title(app.UIAxes_boot, 'Bootstrap Distribution');
    xlabel(app.UIAxes_boot, 'Difference');
    ylabel(app.UIAxes_boot, 'Frequency');
    hold(app.UIAxes_boot, 'off');

    % Plot gate type count
    gate_types = [ex.bootstrap(1:iboot).gate_type];
    counts = histcounts(gate_types, 1:4);
    b = bar(app.UIAxes_gate, counts);
    b.FaceColor = tableau_10('pink');
    xticklabels(app.UIAxes_gate, {'1','2','3'});
    ylabel(app.UIAxes_gate, 'Frequency');

    drawnow

    %% Permutation test
    test_stat = diff_2f_mean;
    N_trials = length(diff_2f_vec);
    perm_matrix = zeros(n_permutations,1);

    for iperm = 1:n_permutations
        my_sign = sign(randn(N_trials,1));
        perm_matrix(iperm) = mean(diff_2f_vec.*my_sign);
    end

    sig_thresh = prctile(perm_matrix,my_prctile);
    
    % Save to ex
    ex.bootstrap(iboot).perm_test_stat = test_stat;
    ex.bootstrap(iboot).perm_sig_threshold = sig_thresh;
    ex.bootstrap(iboot).perm_test_result = test_stat > sig_thresh;
    
    fprintf('\nPermutation test result \nSignificance threshold: %1.3f\n Test statistic: %1.3f\n ',sig_thresh, test_stat)
    
    %% Make decision
    if lower_CI > 0
        % response found
        ex.decision(ex.counter.iamp).resp_found = 1;
        ex.decision(ex.counter.iamp).current_amplitude = current_amplitude;
        fprintf('\nSignificant difference between ON and OFF responses found!\n')
    else
        ex.decision(ex.counter.iamp).resp_found = 0;
        ex.decision(ex.counter.iamp).current_amplitude = current_amplitude;
        fprintf('\nNo significant difference between ON and OFF responses\n')
    end

    % Save values
    if ex.decision(ex.counter.iamp).resp_found == 1 || N_valid_trials >= max_trials
        ex.model.stim_ON_2f_vec = [ex.model.stim_ON_2f_vec {stim_ON_2f_vec}]; % (trials x stimulus amplitude)
        ex.model.stim_OFF_2f_vec = [ex.model.stim_OFF_2f_vec {stim_OFF_2f_vec}]; % (trials x stimulus amplitude)
        ex.model.diff_2f_vec = [ex.model.diff_2f_vec {diff_2f_vec}];
        ex.model.amplitude_vec = [ex.model.amplitude_vec current_amplitude]; % (1 x N_tested_amplitudes)
    end
else
    %% Signal too noisy
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.decision(ex.counter.iamp).current_amplitude = current_amplitude;
    fprintf('\nNo significant difference between ON and OFF responses\n')
end

