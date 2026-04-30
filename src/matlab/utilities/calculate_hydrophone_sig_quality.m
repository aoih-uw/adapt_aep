function ex = calculate_hydrophone_sig_quality(ex)
fs = ex.info.recording.sampling_rate_hz;
iblock = ex.counter.iblock;
hydrophone_mV = ex.raw(iblock).hydrophone_mV;
hydrophone_gain_mV_per_Pa = ex.info.recording.hydrophone_gain_mV_per_Pa;
ramp_duration_ms = ex.info.stimulus.ramp_duration_ms;
ramp_duration_samples = ceil(ramp_duration_ms*(1/1000)*fs);
period_length_samples = length(ex.info.stimulus.waveform);
stimulus_freq = ex.info.stimulus.frequency_hz;
target_freq_range = ex.info.analysis.doub_freq_range_hz;

jitter_vec = ex.block(iblock).jitter;
phase_vec = ex.block(iblock).phase_vec;
latency_samples = ex.info.recording.latency_samples;

[stim_ON , stim_OFF] = extract_stim_ON_OFF(latency_samples, period_length_samples, jitter_vec, hydrophone_mV);

% Remove the onramp/offramp samples from stim_ON to get full amplitude
% portion of signal to get best sense of stimulus amplitude
stim_ON = stim_ON(:,ramp_duration_samples:end-ramp_duration_samples);

% Calculate dB RMS re 1 microVolt
for itrial = 1:size(stim_ON,1)
[~ , stim_ON_dB(itrial)] = convert_mV_to_dB_spl(stim_ON(itrial,:),hydrophone_gain_mV_per_Pa);

[~ , stim_OFF_dB(itrial)] = convert_mV_to_dB_spl(stim_OFF(itrial,:),hydrophone_gain_mV_per_Pa);
end

ex.block(iblock).hydrophone.stim_ON_rms_dB_spl = mean(stim_ON_dB);
ex.block(iblock).hydrophone.stim_OFF_rms_dB_spl = mean(stim_OFF_dB);

%% Calculate SNR of stim_ON
% First flip the negative phases so signal averaging here works in our
% favor here
stim_ON_same_phase = phase_vec.*stim_ON;
mean_ON = mean(stim_ON_same_phase);
[~, freq_vec, fft_ON] = calc_fft(mean_ON,fs);
ex.block(iblock).hydrophone.stim_ON_snr  = ...
    calculate_fft_snr(fft_ON, freq_vec, stimulus_freq, target_freq_range, 0);