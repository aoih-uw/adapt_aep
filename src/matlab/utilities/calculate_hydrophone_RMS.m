function ex = calculate_hydrophone_RMS(ex)
fs = ex.info.recording.sampling_rate_hz;
iblock = ex.counter.iblock;
hydrophone_mV = ex.raw(iblock).hydrophone_mV;
hydrophone_gain_mV_per_Pa = ex.info.recording.hydrophone_gain_mV_per_Pa;
ramp_duration_ms = ex.info.stimulus.ramp_duration_ms;
ramp_duration_samples = ceil(ramp_duration_ms*(1/1000)*fs);
period_length_samples = length(ex.info.stimulus.waveform);

jitter_vec = ex.block(iblock).jitter;
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