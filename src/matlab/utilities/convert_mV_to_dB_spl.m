function [rms_Pa , rms_dB] = convert_mV_to_dB_spl(signal,microphone_mV_per_Pa)
% signal has to be a vector (1xN_samples)
rms_Pa = rms(signal/microphone_mV_per_Pa);
rms_dB = 20*log10(rms_Pa/1e-6); % re: 1 microPa
