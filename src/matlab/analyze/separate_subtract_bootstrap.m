function ex = separate_subtract_bootstrap(ex)
%% Separate STIM ON (dur_stim) and STIM OFF (pre_stim) periods and calculate
% differences
fs = ex.info.recording.sampling_rate_hz;
kept_trials_filtered = ex.preprocess.kept_trials_filtered;
kept_jitter = ex.preprocess.kept_jitter;
latency_samples = ex.info.recording.latency_samples;
period_length_samps = length(ex.info.stimulus.waveform);
n_bootstrap = ex.info.analysis.n_bootstrap;
double_freq_hz  = ex.info.stimulus.frequency_hz*2;
doub_freq_range_hz = ex.info.analysis.doub_freq_range_hz;

pre_stim_start = latency_samples + kept_jitter + 1;

pre_stim = zeros(size(kept_trials_filtered,1), period_length_samps);
dur_stim = zeros(size(kept_trials_filtered,1), period_length_samps);

for itrial = 1:size(kept_trials_filtered,1)
    cur_pre_stim_start = pre_stim_start(itrial);
    pre_stim(itrial,:) = kept_trials_filtered(itrial,cur_pre_stim_start:cur_pre_stim_start+period_length_samps-1);

    dur_stim_start = cur_pre_stim_start+period_length_samps;
    dur_stim(itrial,:) = kept_trials_filtered(itrial,dur_stim_start:dur_stim_start+period_length_samps-1);
end

%% Calculate ffts and subtract
N_pre = zeros(size(pre_stim,1));
N_dur = zeros(size(pre_stim,1));

freq_vec_pre = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1); % WHy size(pre_stim,2)/2+1 to include nyquist and divide by two to get positive values?
freq_vec_dur = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1);

fft_vals_pre = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1);
fft_vals_dur = zeros(size(pre_stim,1),floor(size(pre_stim,2)/2)+1);

for itrial = 1:size(kept_trials_filtered,1)
[N_pre, freq_vec_pre(itrial,:), fft_vals_pre(itrial,:)] = calc_fft(pre_stim(itrial,:),fs);
[N_dur, freq_vec_dur(itrial,:), fft_vals_dur(itrial,:)] = calc_fft(dur_stim(itrial,:),fs);
end

diffs = fft_vals_dur - fft_vals_pre;

%# Plot diff (make work with app later)
m_diffs = mean(diffs);
s_diffs = std(diffs);
f_diffs = mean(freq_vec_dur);
fill([f_diffs fliplr(f_diffs)], [m_diffs+s_diffs fliplr(m_diffs-s_diffs)], 'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
hold on;
plot(f_diffs, m_diffs, 'b', 'LineWidth', 1);
yline(0,'--')


%% Bootstrap
% Select double freq response values
lower_end = double_freq_hz - doub_freq_range_hz;
upper_end = double_freq_hz + doub_freq_range_hz;

doub_freq_resp_mV = mean(diffs(:,freq_vec_pre(1,:) >= lower_end & freq_vec_pre(1,:) <= upper_end),2);

%# How to calculate noise floor?
noise_floor = mean(fft_vals_pre(:,freq_vec_pre(1,:) >= lower_end & freq_vec_pre(1,:) <= upper_end),2);
bootstat = bootstrp(n_bootstrap,@mean,doub_freq_resp_mV);

%% Calculate 95% CI
lower_CI = prctile(bootstat, 2.5);
upper_CI = prctile(bootstat, 97.5);

fprintf('\nCI range: [ %.3f , %.3f ]',lower_CI, upper_CI)
% Make decision
if lower_CI > 0 % response found!
    ex.decision(ex.counter.iamp).resp_found 
    ex.model.doub_freq_resp_vec_mV = [ex.model.doub_freq_resp_vec_mV mean(doub_freq_resp_mV,1)];
    ex.model.noise_floor = [ex.model.noise_floor; noise_floor];
    current_amplitude = ex.info.stimulus.amplitude_spl;
    ex.model.amplitude_vec = [ex.model.amplitude_vec current_amplitude];
    fprintf('Significant difference between ON and OFF responses found')
else
    fprintf('\nNo significant difference between ON and OFF responses')
end
