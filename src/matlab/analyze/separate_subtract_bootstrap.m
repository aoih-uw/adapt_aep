function ex = separate_subtract_bootstrap(ex,app)
%% Separate STIM ON (dur_stim) and STIM OFF (pre_stim) periods and calculate
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

if ex.test == 1
    double_freq_hz  = ex.info.stimulus.frequency_hz;
else
    double_freq_hz  = ex.info.stimulus.frequency_hz*2;
end
doub_freq_range_hz = ex.info.analysis.doub_freq_range_hz;
current_amplitude = ex.info.stimulus.amplitude_spl;

% Select double freq response values
lower_end = double_freq_hz - doub_freq_range_hz;
upper_end = double_freq_hz + doub_freq_range_hz;

pre_stim_start = latency_samples + kept_jitter + 1; % Each trial has different jitter, and thus will have different starting points

pre_stim = zeros(size(kept_trials_filtered,1), period_length_samps); % (N_trials x time samples)
dur_stim = zeros(size(kept_trials_filtered,1), period_length_samps);

for itrial = 1:size(kept_trials_filtered,1) % Extract periods by trial
    cur_pre_stim_start = pre_stim_start(itrial);
    pre_stim(itrial,:) = kept_trials_filtered(itrial,cur_pre_stim_start:cur_pre_stim_start+period_length_samps-1);

    dur_stim_start = cur_pre_stim_start+period_length_samps;
    dur_stim(itrial,:) = kept_trials_filtered(itrial,dur_stim_start:dur_stim_start+period_length_samps-1);
end

%% See if noise has averaged down enough to do analysis
if trials_presented == ex.info.adaptive.trials_per_block
    starting_rms = rms(mean(pre_stim));
    ex.noise.starting_rms = starting_rms;
end
starting_rms = ex.noise.starting_rms;
current_rms = rms(mean(pre_stim));
rms_ratio = current_rms/starting_rms;
app.Label_RMS_ratio.Text = sprintf('%.2f', rms_ratio);
fprintf('\nRMS ratio: %1.2f\nTrials in average: %1.0f\n',rms_ratio,trials_presented*N_channels)

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

%% Get dur 2f mean value
doub_freq_dur_vec = mean(fft_vals_dur(:,freq_vec_pre(1,:) >= lower_end & freq_vec_pre(1,:) <= upper_end),2,'omitnan');
while any(isempty(doub_freq_dur_vec)) || any(isnan(doub_freq_dur_vec))
    warning('Did not find eligble frequencies for 2f magnitude calculation. Going to increase range by 1 Hz')
    doub_freq_range_hz = doub_freq_range_hz + 1;
    ex.info.analysis.doub_freq_range_hz  = doub_freq_range_hz;
    lower_end = double_freq_hz - doub_freq_range_hz;
    upper_end = double_freq_hz + doub_freq_range_hz;
    doub_freq_dur_vec = mean(fft_vals_dur(:,freq_vec_pre(1,:) >= lower_end & freq_vec_pre(1,:) <= upper_end),2,'omitnan');
end

%% Subtract ON - OFF for bootstrap
diffs = fft_vals_dur - fft_vals_pre;
doub_freq_diff_vec = mean(diffs(:,freq_vec_pre(1,:) >= lower_end & freq_vec_pre(1,:) <= upper_end),2,'omitnan'); % (N_trials, 1)

%% Determine if peak at 2f is meaningfully different from the other peaks in the dataset
mean_diffs = mean(diffs,1);
selected_freq_vec = freq_vec_pre(1,:);
doub_freq_diff_mean = mean(doub_freq_diff_vec);

% Exclude peaks near harmonics
loc_2f = mod(selected_freq_vec, double_freq_hz) <= doub_freq_range_hz | ...
    mod(selected_freq_vec, double_freq_hz) >= (double_freq_hz - doub_freq_range_hz);
% Exclude peaks near multiples of 60 Hz
loc_60_multiples = mod(selected_freq_vec, 60) <= doub_freq_range_hz | ...
    mod(selected_freq_vec, 60) >= (60 - doub_freq_range_hz);

% Calculate the median value of all peaks except 2f and 60 Hz multiples
noise_distribution = mean_diffs(~loc_2f & ~loc_60_multiples);

noise_median = median(noise_distribution);
noise_mad = mad(noise_distribution, 1);  
peak_criteria = noise_median + noise_mad*mad_criteria*1.4826;

%% Plotting
f_diffs = selected_freq_vec;
m_diffs = mean_diffs;
s_diffs = std(diffs, 0, 1);

% Plot on app axes
reset(app.UIAxes_diff_fft);
fill(app.UIAxes_diff_fft, [f_diffs fliplr(f_diffs)], [m_diffs+s_diffs fliplr(m_diffs-s_diffs)], tableau_10('blue'), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
hold(app.UIAxes_diff_fft, 'on');
plot(app.UIAxes_diff_fft, f_diffs, m_diffs, 'Color', tableau_10('blue'), 'LineWidth', 1.5);
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
max_vals = maxk(mean_diffs, 5);
% Do not get the top value in case the 2f response is that max value
max_val = mean(max_vals(2:5));

%% Decision Logic
if doub_freq_diff_mean > peak_mult*max_val || doub_freq_diff_mean > peak_criteria && rms_ratio < 0.5
    [bootstat, lower_CI, upper_CI] = calculate_bootstrap(ex, doub_freq_diff_vec);
    fprintf('\nBootstrapping CI range: [ %.3f , %.3f ]',lower_CI, upper_CI)

    % Plot bootstrapped distribution on app axes
    reset(app.UIAxes_boot)
    histogram(app.UIAxes_boot, bootstat, 'FaceColor', tableau_10('blue'));
    hold(app.UIAxes_boot, 'on');
    xline(app.UIAxes_boot, 0, '--');
    xline(app.UIAxes_boot, lower_CI, 'Color', tableau_10('red'), LineWidth=1.5)
    xline(app.UIAxes_boot, upper_CI, 'Color', tableau_10('red'), LineWidth=1.5)
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
        ex.plot.diffs_fft = diffs;
        ex.plot.durs_fft = fft_vals_dur;
        ex.plot.freq_vec = selected_freq_vec;
        ex.model.doub_freq_diff_vec = [ex.model.doub_freq_diff_vec {doub_freq_diff_vec}]; % (trials x stimulus amplitude)
        ex.model.doub_freq_dur_vec = [ex.model.doub_freq_dur_vec {doub_freq_dur_vec}]; % (trials x stimulus amplitude)
        ex.model.noise_floor = [ex.model.noise_floor {noise_distribution}]; % (trials x stimulus amplitude)
        ex.model.amplitude_vec = [ex.model.amplitude_vec current_amplitude]; % (1 x N_tested_amplitudes)
        fprintf('\nSignificant difference between ON and OFF responses found!\n')
    else
        ex.decision(ex.counter.iamp).resp_found = 0;
        ex.plot.diffs_fft = diffs;
        ex.plot.durs_fft = fft_vals_dur;
        ex.plot.freq_vec = selected_freq_vec;
        ex.model.doub_freq_diff_vec_temp = doub_freq_diff_vec;
        ex.model.doub_freq_dur_vec_temp = doub_freq_dur_vec;
        ex.model.noise_floor_temp = noise_distribution;
        fprintf('\nNo significant difference between ON and OFF responses\n')
    end
else
    %% Signal too noisy
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.plot.diffs_fft = diffs;
    ex.plot.durs_fft = fft_vals_dur;
    ex.plot.freq_vec = selected_freq_vec;
    ex.model.doub_freq_diff_vec_temp = doub_freq_diff_vec;
    ex.model.doub_freq_dur_vec_temp = doub_freq_dur_vec;
    ex.model.noise_floor_temp = noise_distribution;
    fprintf('\nNo significant difference between ON and OFF responses\n')
end

