function [hydrophone_rms_dB, rec_data_mV, mean_hydrophone_sig] = measure_calibration_stimuli( ...
    calibration_stim, trigger_stim, waveform, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, loopback_idx, ...
    hydrophone_voltage_scaling_factor_V, stimulus_freq, ramp_duration_ms, ...
    hydrophone_gain_V_per_Pa, fs)

    stimulus = [calibration_stim' trigger_stim'];
    
    rec_data_mV = present_sound(stimulus, ...
        input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, ...
        1, hydrophone_voltage_scaling_factor_V);
    
    mean_loopback_sig = mean(squeeze(rec_data_mV(:,:,loopback_idx)),1);
    mean_hydrophone_sig = mean(squeeze(rec_data_mV(:,:,hydrophone_idx)),1);
    
    latency_samples = find(mean_loopback_sig > 0.5,1,'first');
    
    filtered_mean_hydrophone_sig = bandpass_filter(mean_hydrophone_sig,stimulus_freq,stimulus_freq, 4);
    
    ramp_samples = ceil((ramp_duration_ms/1000)*fs);
    start_idx = latency_samples + ramp_samples;
    end_idx = latency_samples + length(waveform) - ramp_samples;
    full_amp_hydrophone_sig = filtered_mean_hydrophone_sig(start_idx:end_idx);
    
    hydrophone_rms_pa = rms(full_amp_hydrophone_sig/hydrophone_gain_V_per_Pa);
    hydrophone_rms_dB = 20*log10(hydrophone_rms_pa/1e-6); % re: 1 microPa

end