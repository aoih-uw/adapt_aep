function ex = separate_subtract_bootstrap(ex,app)
%% Separate STIM ON (stim_ON) and STIM OFF (stim_OFF) periods and calculate
% differences
fs = ex.info.recording.sampling_rate_hz;
kept_trials_filtered = ex.kept.trials_filtered;
kept_jitter = ex.kept.jitter;
latency_samples = ex.info.recording.latency_samples;
period_length_samps = length(ex.info.stimulus.waveform);
cla(app.UIAxes_boot)
iamp = ex.counter.iamp;
trials_presented = ex.trial_count(iamp);
mad_criteria = ex.info.analysis.mad_criteria;
peak_mult = ex.info.analysis.peak_mult;
N_channels = ex.info.channels.n_channels;
max_trials = ex.info.adaptive.max_trials;
min_trials_for_analysis = ex.info.adaptive.min_trials_for_analysis;
run_bootstrap = 0;

if ex.test == 1
    double_freq_hz  = ex.info.stimulus.frequency_hz;
else
    double_freq_hz  = ex.info.stimulus.frequency_hz*2;
end
doub_freq_range_hz = ex.info.analysis.doub_freq_range_hz;
current_amplitude = ex.info.stimulus.amplitude_spl;

stim_OFF_start = latency_samples + kept_jitter + 1; % Each trial has different jitter, and thus will have different starting points

stim_OFF = zeros(size(kept_trials_filtered,1), period_length_samps); % (N_trials x time samples)
stim_ON = zeros(size(kept_trials_filtered,1), period_length_samps);

for itrial = 1:size(kept_trials_filtered,1) % Extract periods by trial
    cur_stim_OFF_start = stim_OFF_start(itrial);
    stim_OFF(itrial,:) = kept_trials_filtered(itrial,cur_stim_OFF_start:cur_stim_OFF_start+period_length_samps-1);

    stim_ON_start = cur_stim_OFF_start+period_length_samps;
    stim_ON(itrial,:) = kept_trials_filtered(itrial,stim_ON_start:stim_ON_start+period_length_samps-1);
end

%% See if noise has averaged down enough to do analysis
if trials_presented == ex.info.adaptive.trials_per_block
    starting_rms = rms(mean(stim_OFF));
    ex.noise.starting_rms = starting_rms;
end
starting_rms = ex.noise.starting_rms;
current_rms = rms(mean(stim_OFF));
rms_ratio = current_rms/starting_rms;
app.Label_RMS_ratio.Text = sprintf('%.2f', rms_ratio);
fprintf('\nRMS ratio: %1.2f\nTrials in average: %1.0f\n',rms_ratio,trials_presented*N_channels)

%% Calculate ffts and subtract
N_stim_OFF = zeros(size(stim_OFF,1),1);
N_stim_ON = zeros(size(stim_OFF,1),1);

freq_vec_stim_OFF = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1);
freq_vec_stim_ON = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1);

fft_vals_stim_OFF = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1); % Nyquist shannon theorem you can only represent frequencies up to half of the sampling rate
fft_vals_stim_ON = zeros(size(stim_OFF,1),floor(size(stim_OFF,2)/2)+1);

for itrial = 1:size(stim_OFF,1)
    [N_stim_OFF(itrial), freq_vec_stim_OFF(itrial,:), fft_vals_stim_OFF(itrial,:)] = calc_fft(stim_OFF(itrial,:),fs); %# Will calc_fft handle NaNs? Actually this shouldn't be a problem because we are selecting the periods
    [N_stim_ON(itrial), freq_vec_stim_ON(itrial,:), fft_vals_stim_ON(itrial,:)] = calc_fft(stim_ON(itrial,:),fs);
end

freq_vec = freq_vec_stim_ON(1,:);

%% Get STIM ON 2f value across all trials
[doub_freq_range_hz,doub_freq_stim_ON_vec] = ...
    find_fft_bins(double_freq_hz, doub_freq_range_hz, fft_vals_dur, freq_vec);

%% DIFF: Subtract ON - OFF for bootstrap
diffs = fft_vals_stim_ON - fft_vals_stim_OFF;
% Get DIFF 2f value across all trials
[doub_freq_range_hz, doub_freq_diff_vec] = ...
    find_fft_bins(double_freq_hz, doub_freq_range_hz, diffs, freq_vec);

%% Calculate mean diff 2f magnitude to compare to other peaks in diff
doub_freq_diff_mean = mean(doub_freq_diff_vec); % Collapse 2f diff bin means across trials

%% Calculate fft noise floor (i.e., magnitude @ 2f stim OFF)
for itrial = 1:size(diffs,1)
    temp = fft_vals_stim_OFF(itrial,:); % Get the magnitude value at 2f in the stim OFF period to compare to stim ON period for the model
    [doub_freq_range_hz, noise_distribution(itrial)] = ...
    find_fft_bins(double_freq_hz, doub_freq_range_hz, temp, freq_vec);
end

noise_median = median(noise_distribution);
noise_mad = mad(noise_distribution, 1);  
peak_criteria = noise_median + noise_mad*mad_criteria*1.4826;

%% Plotting
f_diffs = freq_vec;
mean_diffs = mean(diffs,1); % Collapse diff ffts across trials
s_diffs = std(diffs, 0, 1);

% Plot on app axes
reset(app.UIAxes_diff_fft);
fill(app.UIAxes_diff_fft, [f_diffs fliplr(f_diffs)], [mean_diffs+s_diffs fliplr(mean_diffs-s_diffs)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold(app.UIAxes_diff_fft, 'on');
plot(app.UIAxes_diff_fft, f_diffs, mean_diffs, 'Color', tableau_10('blue'), 'LineWidth', 1.5);
xlim(app.UIAxes_diff_fft, [(double_freq_hz-(double_freq_hz/1.1))*2, (double_freq_hz+(double_freq_hz/1.1))*2]);
title(app.UIAxes_diff_fft, 'Difference FFT');
grid(app.UIAxes_diff_fft, 'on');
yline(app.UIAxes_diff_fft, 0, '--');
xline(app.UIAxes_diff_fft, double_freq_hz,'--')
yline(app.UIAxes_diff_fft, peak_criteria ,'-','Color',tableau_10('pink'),'LineWidth',1.5)
xlabel(app.UIAxes_diff_fft,'Frequency (Hz)')
ylabel(app.UIAxes_diff_fft,'Amplitude (\muV)')
hold(app.UIAxes_diff_fft, 'off');

drawnow

%% Get max vals
if length(mean_diffs) > 5
max_vals = maxk(mean_diffs, 5);
% Do not get the top value in case the 2f response is that max value
max_val = median(max_vals(2:5));
else
    keyboard
end

%% Assign values to ex.block
ex.fft.diffs = diffs;
ex.fft.stim_ON = fft_vals_stim_ON;
ex.fft.stim_OFF = fft_vals_stim_OFF;
ex.fft.freq_vec = freq_vec;
ex.fft.stim_ON_2f_vec = doub_freq_stim_ON_vec;
ex.fft.stim_OFF_2f_vec = noise_distribution;
ex.fft.diff_2f_vec = doub_freq_diff_vec;

%% Decision Logic
% Run bootstrap if...
% 1. When mean difference FFT @2f is 5x greater than mean of 2 through 5th largest peaks
% 2. If RMS of signal has reduced to 0.5 AND the mean diff 2f value > peak_criteria
% 3. Or if we have hit the trial limit

if doub_freq_diff_mean > peak_mult*max_val 
    run_bootstrap = 1;
    gate_type = 1;
elseif mean(doub_freq_stim_ON_vec,1) > peak_criteria && rms_ratio < 0.5 && trials_presented > min_trials_for_analysis
    run_bootstrap = 1;
    gate_type = 2;
elseif trials_presented == max_trials
    run_bootstrap = 1;
    gate_type = 3;
end

if run_bootstrap
    ex.counter.iboot = ex.counter.iboot + 1;
    iboot = ex.counter.iboot;

    [bootstat, lower_CI, upper_CI] = calculate_bootstrap(ex, doub_freq_diff_vec);
    fprintf('\nBootstrapping CI range: [ %.3f , %.3f ]',lower_CI, upper_CI)
    
    % Save to boot
    ex.boot(iboot).bootstat = bootstat;
    ex.boot(iboot).gate_type = gate_type;
    ex.boot(iboot).lower_CI = lower_CI;
    ex.boot(iboot).upper_CI = upper_CI;

    % Plot bootstrapped distribution on app axes
    reset(app.UIAxes_boot)
    histogram(app.UIAxes_boot, bootstat, 'FaceColor', tableau_10('blue'));
    hold(app.UIAxes_boot, 'on');
    xline(app.UIAxes_boot, 0, '--');
    xline(app.UIAxes_boot, lower_CI, 'Color', tableau_10('red'), 'LineWidth', 1.5)
    xline(app.UIAxes_boot, upper_CI, 'Color', tableau_10('red'), 'LineWidth', 1.5)
    xlim(app.UIAxes_boot, 'auto');
    cur_xlim = xlim(app.UIAxes_boot);
    xlim(app.UIAxes_boot, [-max(abs(cur_xlim)), max(abs(cur_xlim))]);
    title(app.UIAxes_boot, 'Bootstrap Distribution');
    xlabel(app.UIAxes_boot, 'Difference');
    grid(app.UIAxes_boot, 'on');
    ylabel(app.UIAxes_boot, 'Frequency');
    hold(app.UIAxes_boot, 'off');

    drawnow
    
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
    if ex.decision(ex.counter.iamp).resp_found == 1 || trials_presented == max_trials
        ex.model.doub_freq_stim_ON_vec = [ex.model.doub_freq_stim_ON_vec {doub_freq_stim_ON_vec}]; % (trials x stimulus amplitude)
        ex.model.noise_floor = [ex.model.noise_floor {noise_distribution}]; % (trials x stimulus amplitude)
        ex.model.amplitude_vec = [ex.model.amplitude_vec current_amplitude]; % (1 x N_tested_amplitudes)
        fprintf('\nSignificant difference between ON and OFF responses found!\n')
    else
        fprintf('\nNo significant difference between ON and OFF responses\n')
    end
else
    %% Signal too noisy
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.decision(ex.counter.iamp).current_amplitude = current_amplitude;
    fprintf('\nNo significant difference between ON and OFF responses\n')
end

