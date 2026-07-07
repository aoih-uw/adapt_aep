function ex = calculate_hydrophone_sig_quality(ex)
%% Calculates hydrophone signal SNR
%% Assign varables
fs = ex.info.recording.sampling_rate_hz;
iblock = ex.counter.iblock;
hydrophone_mV = ex.raw(iblock).hydrophone_mV;
hydrophone_gain_mV_per_Pa = ex.info.recording.hydrophone_gain_mV_per_Pa;
ramp_duration_ms = ex.info.stimulus.ramp_duration_ms;
ramp_duration_samples = ceil(ramp_duration_ms/1000*fs);
period_length_samples = length(ex.info.stimulus.waveform);
stimulus_freq = ex.info.stimulus.frequency_hz;
target_freq_range = ex.info.stimulus.range_2f_hz;
waveform = ex.info.stimulus.waveform;
trim_stim_pre_dur_ms = ex.info.stimulus.trim_stim_pre_dur_ms;
jitter_vec = ex.block(iblock).jitter;
phase_vec = ex.block(iblock).phase_vec;
latency_samples = ex.info.recording.latency_samples;
mad_to_std = ex.info.signal_quality.mad_to_std;
if isfield(ex.info, 'mixed')
    ischedule = ex.counter.ischedule;
    stimulus_type_idx = ex.info.mixed.test_schedule(ischedule,1);
else
    ischedule = [];
end

if (isfield(ex.info,'mixed') && strcmp(ex.info.mixed.stim_name{stimulus_type_idx}, 'trim')) || ...
        strcmp(ex.info.experiment.exp_type, 'Timed') ||  strcmp(ex.info.experiment.exp_type, 'Static trial count')
    for itrial = 1:size(hydrophone_mV,1)
        stim_start = latency_samples + jitter_vec(itrial) + round(trim_stim_pre_dur_ms/1e3*fs); % stimulus just begins (i.e., start of onramp)
        stim_OFF(itrial,:) = hydrophone_mV(itrial,1:stim_start-1-jitter_vec(itrial)); % Jitter duration will be different for each trial so just remove it
        full_amp_start = stim_start+ramp_duration_samples;
        stim_ON(itrial,:) = hydrophone_mV(itrial,full_amp_start: full_amp_start+length(waveform)-(ramp_duration_samples*2)-1);
    end
elseif strcmp(ex.info.experiment.exp_type, 'Adaptive') || (isfield(ex.info,'mixed') && strcmp(ex.info.mixed.stim_name{stimulus_type_idx}, 'ONOFF'))
    [stim_ON , stim_OFF] = extract_stim_ON_OFF(latency_samples, period_length_samples, jitter_vec, ramp_duration_samples, hydrophone_mV);
end

% Filter the stim OFF signal to only include the current stimulus frequency
stim_OFF_filt = zeros(size(stim_OFF,1), size(stim_OFF,2));
stim_ON_filt = zeros(size(stim_ON,1), size(stim_ON,2));

d = designfilt('bandpassfir', 'FilterOrder', 4, ...
    'CutoffFrequency1', stimulus_freq-0.5, 'CutoffFrequency2', stimulus_freq+0.5, ...
    'SampleRate', fs);
for itrial = 1:size(stim_OFF,1)
    stim_OFF_filt(itrial,:) = bandpassfilter(stim_OFF(itrial,:),d);
    stim_ON_filt(itrial,:) = bandpassfilter(stim_ON(itrial,:),d);
end

%% Calculate dB RMS of time domain OFF/ON periods re 1 microVolt (Just RMS amplitude by period)
% Preallocate
stim_ON_dB = zeros(itrial,1);
stim_OFF_dB = zeros(itrial,1);
for itrial = 1:size(stim_ON,1)
[~ , stim_ON_dB(itrial)] = convert_mV_to_dB_spl(stim_ON_filt(itrial,:),hydrophone_gain_mV_per_Pa);

[~ , stim_OFF_dB(itrial)] = convert_mV_to_dB_spl(stim_OFF_filt(itrial,:),hydrophone_gain_mV_per_Pa);
end

% Sav to ex structure
ex.block(iblock).hydrophone.stimulus_rms = median(stim_ON_dB);
ex.block(iblock).hydrophone.stimulus_rms_mad = median(abs(ex.block(iblock).hydrophone.stimulus_rms - stim_ON_dB))*mad_to_std;
ex.block(iblock).hydrophone.tank_nf_rms = median(stim_OFF_dB);
ex.block(iblock).hydrophone.tank_nf_rms_mad = median(abs(ex.block(iblock).hydrophone.tank_nf_rms-stim_OFF_dB))*mad_to_std;

%% Calculate dB SNR of stim_ON (Stimulus signal relative to noise floor)
% First flip the negative phases so signal averaging here works in our favor here
stim_ON_same_phase = phase_vec.*stim_ON;

% Preallocate
N_trials = size(stim_ON_same_phase,1);
N_samples = floor(size(stim_ON_same_phase,2)/2)+1;
freq_vec = zeros(N_trials,N_samples);
fft_ON = zeros(N_trials,N_samples);

% Calculate dB SNR of stimulus (compare across other frequencies in same trial)
for itrial = 1:N_trials
[~, freq_vec(itrial,:), fft_ON(itrial,:)] = calc_fft(stim_ON_same_phase(itrial,:),fs);
end
freq_vec = freq_vec(1,:);
selected_idx = freq_vec > 1 & freq_vec < 5000;
freq_vec = freq_vec(1,selected_idx);
fft_ON = fft_ON(:,selected_idx);

my_snr = zeros(N_trials,1);
for itrial = 1:N_trials
my_snr(itrial) = calculate_fft_snr(fft_ON(itrial,:), freq_vec, stimulus_freq, target_freq_range, 0);
end
ex.block(iblock).hydrophone.stim_ON_snr_median  = median(my_snr);
ex.block(iblock).hydrophone.stim_ON_snr_mad = median(abs(ex.block(iblock).hydrophone.stim_ON_snr_median - my_snr))*mad_to_std;