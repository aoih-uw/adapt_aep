function [hydrophone_rms_dB, rec_data_mV, mean_hydrophone_sig] = ...
    measure_calibration_stimuli(ex, calibration_stim, trigger_stim, waveform,...
    stimulus_freq, fs)

% Create block of calibration stimuli
calibration_stim = repmat(calibration_stim,10,1);
trigger_stim = repmat(trigger_stim,10,1);
stimulus = cat(3,calibration_stim,trigger_stim);

% Initialize present_sound variables
[ex, ~, ~, ~, output_channels, ...
    input_channels, hydrophone_idx, loopback_idx, electrode_idx, ...
    electrode_V, hydrophone_V] ...
        = init_present_sound_variables(ex, stimulus(:,:,1));

% Initialize other variables
ramp_duration_ms = ex.info.stimulus.ramp_duration_ms;
hydrophone_gain_mV_per_Pa = ex.info.recording.hydrophone_gain_mV_per_Pa;

rec_data_mV = present_sound(stimulus, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, ...
    electrode_V, ...
    hydrophone_V);

mean_loopback_sig = mean(squeeze(rec_data_mV(:,:,loopback_idx)),1);
mean_hydrophone_sig = mean(squeeze(rec_data_mV(:,:,hydrophone_idx)),1);

latency_samples = find(mean_loopback_sig > 0.5,1,'first');
filtered_mean_hydrophone_sig = bandpassfilter(mean_hydrophone_sig,stimulus_freq, stimulus_freq+0.1, 4, fs);

ramp_samples = ceil((ramp_duration_ms/1000)*fs);
start_idx = latency_samples + ramp_samples + 1;
end_idx = start_idx + length(waveform) - ramp_samples*2 - 1; % ramp_samples*2 already included in length(waveform)
full_amp_hydrophone_sig = filtered_mean_hydrophone_sig(start_idx:end_idx);

[~ , hydrophone_rms_dB] = convert_mV_to_dB_spl(full_amp_hydrophone_sig,hydrophone_gain_mV_per_Pa);

end