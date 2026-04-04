function ex = run_calibrate_stimulus(app, ex)
%% Information
% Fireface Correction Factor
% Stimulus sound pressure (Pa) -> Hydrophone measurement -> Amplifier (100 mV/Pa or 0.1 V/Pa) -> Fireface (signal*0.2044) -> Recorded voltage
% Target = 130 dB SPL: re: 1 uPa = (20*log10(3.16Pa/0.000001Pa)
% 3.16 Pa RMS = 3.16* sqrt(2) = 4.47 Pa peak amplitude
% 316 mV peak (0.316 V) when hydrophone amplifier is set to 100 mV/Pa
% The equivalent reading on the FireFace should be 0.316 * 0.2044 = 0.0646

%% Define variables
fs = ex.info.recording.sampling_rate_hz;
waveform = ex.info.stimulus.waveform;

stimulus_freq = ex.info.stimulus.frequency_hz;
target_level = ex.info.calibration.target_amp_spl;
correction_tolerance_dB = ex.info.calibration.correction_tolerance_dB;
ramp_duration_ms = ex.info.stimulus.ramp_duration_ms;

input_channels = ex.info.recording.DAC_input_channels;
input_channel_names = ex.info.recording.DAC_input_channel_names;
loopback_idx = find(strcmp(input_channel_names, 'Loopback'));
hydrophone_idx = find(strcmp(input_channel_names, 'Hydrophone'));
electrode_idx = find(strncmp(input_channel_names, 'Ch',2));
output_channels = ex.info.recording.DAC_output_channels;
hydrophone_voltage_scaling_factor_V = ex.info.recording.hydrophone_voltage_scaling_factor_V;
electrode_voltage_scaling_factor_V = ex.info.recording.electrode_voltage_scaling_factor_V;
hydrophone_gain_mV_per_Pa = ex.info.recording.hydrophone_gain_mV_per_Pa;

ex.info.calibration.initial_calibration_complete = 0;
ex.info.calibration.check_passed = 0;

fprintf('\nStarting calibration...\n')

%% Create stimuli
% Create calibration stimulus (Send to speaker)
pre_pause = zeros(1,fs*0.1); % 100 ms pause vector
post_pause = zeros(1,fs*0.5); % 500 ms pause vector
calibration_stim = [pre_pause waveform post_pause];

% Create trigger stimulus (Send to loopback, allows measurment of system latency)
waveform_with_trig = waveform; % Force first sample to 1 as trigger
waveform_with_trig(1) = 1;
trigger_stim = [pre_pause waveform_with_trig post_pause];

%% Scale stimuli amplitude
% Begin with an output voltage of 0.01, equivalent to ~40 dB of headroom
% Fireface output = 5*digital value
base_level = 10^((target_level-170)/20);
calibration_stim = base_level.*calibration_stim; % start 40 dB down from fs, but ensure that 0.01 associated voltage is waaay below the max output of the speaker

% Measure calibration stimuli
[hydrophone_rms_dB, rec_data_mV, mean_hydrophone_sig] = ...
measure_calibration_stimuli( ...
    calibration_stim, trigger_stim, waveform,...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, loopback_idx, ...
    hydrophone_voltage_scaling_factor_V, electrode_voltage_scaling_factor_V, ...
    stimulus_freq, ramp_duration_ms, ...
    hydrophone_gain_mV_per_Pa, fs);

%% Save values
ex.info.calibration.initial_calibration_complete = 1;
ex.info.calibration.uncorrected_levels = hydrophone_rms_dB;
correction_factor_dB = target_level-hydrophone_rms_dB;
ex.info.calibration.correction_factor_dB = correction_factor_dB;
ex.info.calibration.correction_factor_linear = 10.^(correction_factor_dB/20);
ex.info.calibration.signals = rec_data_mV;

%% Update GUI PLots
% Update labels
app.label_uncorr_level.Text = string(hydrophone_rms_dB);
app.label_corr_factor.Text = string(correction_factor_dB);

% Time domain
n_samples = length(mean_hydrophone_sig);
time_vector = (0:n_samples-1)/fs;
plot(app.ax_hydrophone, time_vector, mean_hydrophone_sig)

% Frequency domain
[~, freq_vec, fft_vals] = calc_fft(mean_hydrophone_sig,fs);
plot(app.ax_hydrophone_spectra, freq_vec,fft_vals)
xlim(app.ax_hydrophone_spectra, [0, 1000])

drawnow;

%% Check if stimulus amplitude is within range with correction factor
fprintf('\nCorrection factor = %.3f dB. Now checking correction factor effectiveness.\n', correction_factor_dB)

% Apply new correction factor
target_calibration_stim = ex.info.calibration.correction_factor_linear*calibration_stim;

% Measure calibration stimuli
[hydrophone_rms_dB, rec_data_mV, mean_hydrophone_sig] = ...
measure_calibration_stimuli( ...
    target_calibration_stim, trigger_stim, waveform, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, loopback_idx, ...
    hydrophone_voltage_scaling_factor_V, electrode_voltage_scaling_factor_V, ...
    stimulus_freq, ramp_duration_ms, ...
    hydrophone_gain_mV_per_Pa, fs);

%% Save values
ex.info.calibration.corrected_level = hydrophone_rms_dB;

%% Update GUI
% Update labels
app.label_corr_level.Text = string(hydrophone_rms_dB);

% Time domain
n_samples = length(mean_hydrophone_sig);
time_vector = (0:n_samples-1)/fs;
plot(app.ax_hydrophone, time_vector, mean_hydrophone_sig)

% Frequency domain
[~, freq_vec, fft_vals] = calc_fft(mean_hydrophone_sig,fs);
plot(app.ax_hydrophone_spectra, freq_vec,fft_vals)

drawnow;

%% Decide if calibration factor is sufficient
if ex.info.calibration.corrected_level >= target_level-correction_tolerance_dB && ...
        ex.info.calibration.corrected_level <= target_level+correction_tolerance_dB % If correction factor worked
    
    ex.info.calibration.check_passed = 1;
    fprintf('\nTarget level = %.1f +/- %.1f \nCorrected level = %.3f \nEffective calibration factor identified. Calibration complete.\n', ...
        target_level, correction_tolerance_dB, hydrophone_rms_dB)
    
    % Save calibration file
    ex.info.calibration.signals = rec_data_mV;    
    filename_root = ex.info.animal.filename_root;
    [~, filename_root] = fileparts(filename_root); % extract just the base name
    time_stamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = fullfile('..', '..', 'data', 'calibration', strcat(filename_root, '_calibration_', time_stamp));

    calibration = ex.info.calibration;
    save(filename, 'calibration')

else
    fprintf(['\nTarget level = %.1f +/- %.1f \nCorrected level = %.1f\n Correction factor ineffective.' ...
        'Investigate tank acoustic environment further before reattempting calibration\n'], ...
        target_level, correction_tolerance_dB, hydrophone_rms_dB)
end
end

