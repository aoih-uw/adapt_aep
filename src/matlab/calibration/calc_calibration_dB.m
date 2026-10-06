function [hydro_rms_dB, accel_dB, mean_hydrophone_sig, mean_accel_sigs_mV] = calc_calibration_dB(ex,rec_data_mV, waveform, ...
    recording_info, stimulus_info, test_accel)
% hydro_rms_dB
% accel_rms_dB = struct

% Unpack_variables
fs = recording_info.sampling_rate_hz;
hydrophone_gain_mV_per_Pa = recording_info.hydrophone_gain_mV_per_Pa;
ramp_duration_ms = stimulus_info.ramp_duration_ms;
stimulus_freq = stimulus_info.frequency_hz;
accel_dB = struct();
mean_accel_sigs_mV = [];
input_channel_names = ex.info.recording.DAC_input_channel_names;
hydrophone_idx = find(strcmp(input_channel_names, 'Hydrophone'));
loopback_idx = find(strcmp(input_channel_names, 'Loopback'));
accel_idx = find(ismember(ex.info.recording.DAC_input_channels, ...
    ex.info.accel.DAC_input_channels(3:end)));

%% Hydrophone
% Calculate mean
mean_loopback_sig = mean(squeeze(rec_data_mV(:,:,loopback_idx)),1);
mean_hydrophone_sig = mean(squeeze(rec_data_mV(:,:,hydrophone_idx)),1);

% Identify latency samples
latency_samples = find(mean_loopback_sig > 0.5*max(mean_loopback_sig),1,'first');
if isempty(latency_samples)
    keyboard
    error('Issue with finding latency threshold, check hardware and try again')
end

% Calculate signal start/end indexes based on latency
ramp_samples = round((ramp_duration_ms/1000)*fs);
start_idx = latency_samples + ramp_samples;
end_idx = start_idx + length(waveform) - ramp_samples*2 - 1; % ramp_samples*2 already included in length(waveform)

% Filter hydrophone signal
d = designfilt('bandpassfir', 'FilterOrder', 4, ...
    'CutoffFrequency1', stimulus_freq-3, 'CutoffFrequency2', stimulus_freq+3, ...
    'SampleRate', fs);
filtered_mean_hydrophone_sig = bandpassfilter(mean_hydrophone_sig, d);
full_amp_hydrophone_sig = filtered_mean_hydrophone_sig(start_idx:end_idx);

% Convert mV values to dB SPL
[~ , hydro_rms_dB] = convert_mV_to_dB_spl(full_amp_hydrophone_sig,hydrophone_gain_mV_per_Pa);
check_for_nans(hydro_rms_dB,'variable')

%% Accelerometer
if test_accel
    % Correct for amplifier gain
    accel_sigs_mV = rec_data_mV(:,:,accel_idx)./ex.info.accel.amp_gain;
    mean_accel_sigs_mV = squeeze(mean(accel_sigs_mV,1))';

    % Filter and trim signals
    sig_set = NaN(3,length(start_idx:end_idx));
    for i = 1:size(mean_accel_sigs_mV,1)
        cur_sig = mean_accel_sigs_mV(i,:);
        filtered_sig = bandpassfilter(cur_sig, d);
        full_amp_sig = filtered_sig(start_idx:end_idx);
        sig_set(i,:) = full_amp_sig;
    end

    % Calculate dB values
    accel_dB = calc_accel_dB(sig_set,ex,accel_dB);
end

