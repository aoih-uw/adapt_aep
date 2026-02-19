function ex = separate_subtract_bootstrap(ex,app)
%% Separate STIM ON (dur_stim) and STIM OFF (pre_stim) periods and calculate
% differences
fs = ex.info.recording.sampling_rate_hz;
kept_trials_filtered = ex.kept.trials_filtered;
kept_jitter = ex.kept.jitter;
latency_samples = ex.info.recording.latency_samples;
period_length_samps = length(ex.info.stimulus.waveform);
n_bootstrap = ex.info.analysis.n_bootstrap;
if ex.test == 1
    double_freq_hz  = ex.info.stimulus.frequency_hz;
else
    double_freq_hz  = ex.info.stimulus.frequency_hz*2;
end
doub_freq_range_hz = ex.info.analysis.doub_freq_range_hz;
current_amplitude = ex.info.stimulus.amplitude_spl;

pre_stim_start = latency_samples + kept_jitter + 1; % Each trial has different jitter, and thus will have different starting points

pre_stim = zeros(size(kept_trials_filtered,1), period_length_samps); % (N_trials x time samples)
dur_stim = zeros(size(kept_trials_filtered,1), period_length_samps);

for itrial = 1:size(kept_trials_filtered,1) % Extract periods by trial
    cur_pre_stim_start = pre_stim_start(itrial);
    pre_stim(itrial,:) = kept_trials_filtered(itrial,cur_pre_stim_start:cur_pre_stim_start+period_length_samps-1);

    dur_stim_start = cur_pre_stim_start+period_length_samps;
    dur_stim(itrial,:) = kept_trials_filtered(itrial,dur_stim_start:dur_stim_start+period_length_samps-1);
end

%% Calculate ffts and subtract
N_pre = zeros(size(pre_stim,1),1);
N_dur = zeros(size(pre_stim,1),1);

freq_vec_pre = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1);
freq_vec_dur = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1);

fft_vals_pre = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1);
fft_vals_dur = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1);
for itrial = 1:size(pre_stim,1)
    [N_pre(itrial), freq_vec_pre(itrial,:), fft_vals_pre(itrial,:)] = calc_fft(pre_stim(itrial,:),fs); %# Will calc_fft handle NaNs? Actually this shouldn't be a problem because we are selecting the periods
    [N_dur(itrial), freq_vec_dur(itrial,:), fft_vals_dur(itrial,:)] = calc_fft(dur_stim(itrial,:),fs);
end

diffs = fft_vals_dur - fft_vals_pre;

%% Calculate mean and std for plotting
f_diffs = freq_vec_pre(1,:); % Use frequency vector from first trial (all should be the same)
m_diffs = mean(diffs, 1); % Mean across trials
s_diffs = std(diffs, 0, 1); % Standard deviation across trials

% Plot on app axes
reset(app.UIAxes_diff_fft);
fill(app.UIAxes_diff_fft, [f_diffs fliplr(f_diffs)], [m_diffs+s_diffs fliplr(m_diffs-s_diffs)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold(app.UIAxes_diff_fft, 'on');
plot(app.UIAxes_diff_fft, f_diffs, m_diffs, 'Color', tableau_10('blue'), 'LineWidth', 1.5);
xlim(app.UIAxes_diff_fft, [double_freq_hz-(double_freq_hz/1.1), double_freq_hz+(double_freq_hz/1.1)]);
title(app.UIAxes_diff_fft, 'Difference FFT');
grid(app.UIAxes_diff_fft, 'on');
yline(app.UIAxes_diff_fft, 0, '--');
xline(app.UIAxes_diff_fft,double_freq_hz,'--')
xlabel(app.UIAxes_diff_fft,'Frequency (Hz)')
ylabel(app.UIAxes_diff_fft,'Amplitude (mV)')
hold(app.UIAxes_diff_fft, 'off');

pause(0.1)

%% Bootstrap
% Select double freq response values
lower_end = double_freq_hz - doub_freq_range_hz;
upper_end = double_freq_hz + doub_freq_range_hz;

% Collapse across columns to get average value between upper and lower limits
% doub_freq_resp from diff
doub_freq_resp_mV = mean(diffs(:,freq_vec_pre(1,:) >= lower_end & freq_vec_pre(1,:) <= upper_end),2); % (N_trials, 1)

%# Calculate noise floor
% noise measurement at the double frequency response point during pre
noise_floor = mean(fft_vals_pre(:,freq_vec_pre(1,:) >= lower_end & freq_vec_pre(1,:) <= upper_end),2); % (N_trials,1)

% Split bootstrapping group in 1/2 to verify
group_length = length(doub_freq_resp_mV);
rand_group_idx = randperm(group_length,group_length);
idx = 1;
reset(app.UIAxes_boot)
% for irep = 1:2
    % Bootstrap!
    cur_idx = rand_group_idx(idx:idx+(group_length/2)-1);
    cur_group = doub_freq_resp_mV(cur_idx);
    fprintf('\nStarting bootstrap calculation %1.0f/2...', irep)
    tic()
    bootstat = bootstrp(n_bootstrap,@mean,cur_group);
    time_elapsed = toc();
    fprintf('\nBootstrap calculation time: %.3f', time_elapsed);

    % Plot bootstrapped distribution on app axes
    if irep == 1
        histogram(app.UIAxes_boot, bootstat, 'FaceColor', tableau_10('blue'));
        hold(app.UIAxes_boot, 'on');
    else
        histogram(app.UIAxes_boot, bootstat, 'FaceColor', tableau_10('yellow'));
    end
    xline(app.UIAxes_boot, 0, '--');
    xlim(app.UIAxes_boot, 'auto');
    cur_xlim = xlim(app.UIAxes_boot);
    xlim(app.UIAxes_boot, [-max(abs(cur_xlim)), max(abs(cur_xlim))]);
    title(app.UIAxes_boot, 'Bootstrap Distribution');
    xlabel(app.UIAxes_boot, 'Difference');
    grid(app.UIAxes_boot, 'on');
    ylabel(app.UIAxes_boot, 'Frequency');

    pause(0.1)

    %% Calculate 95% CI
    boot_mean(irep) = mean(bootstat);
    boot_std(irep) = std(bootstat);
    lower_CI(irep) = prctile(bootstat, 0.5);
    upper_CI(irep) = prctile(bootstat, 99.5);
    fprintf('\nCI range: [ %.3f , %.3f ]',lower_CI, upper_CI)

    idx = idx + group_length/2;
end

hold(app.UIAxes_boot, 'off');

%% Checks for false positives from random noise
% Check CIs overlap (means distributions are reliable/not noisy)
ci_overlap = boot_mean(1) < boot_mean(2) + boot_std(2) && ...
    boot_mean(1) > boot_mean(2) - boot_std(2);

% Sign consistency (If a response is present, the 2f amplitude should be
% positive anyways!)
group_sign = doub_freq_resp_mV > 0;
percent_pos = sum(group_sign)/group_length;

%% Make decision
if all(lower_CI > 0) && percent_pos > 99 || all(lower_CI > 0) && ci_overlap && percent_pos >= 0.8
    % response found
    ex.decision(ex.counter.iamp).resp_found = 1;
    ex.model.doub_freq_resp_mV = [ex.model.doub_freq_resp_mV {doub_freq_resp_mV}]; % (trials x stimulus amplitude)
    ex.model.noise_floor = [ex.model.noise_floor {noise_floor}]; % (trials x stimulus amplitude)
    ex.model.amplitude_vec = [ex.model.amplitude_vec current_amplitude]; % (1 x N_tested_amplitudes)
    fprintf('\nSignificant difference between ON and OFF responses found!\n')
else
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.model.doub_freq_resp_mV_temp = doub_freq_resp_mV;
    ex.model.noise_floor_temp = noise_floor;
    fprintf('\nNo significant difference between ON and OFF responses\n')
end
