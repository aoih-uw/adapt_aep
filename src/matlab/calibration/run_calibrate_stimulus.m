function ex = run_calibrate_stimulus(app, ex)
%% Information
% Fireface Correction Factor
% Stimulus sound pressure (Pa) -> Hydrophone measurement -> Amplifier (100 mV/Pa or 0.1 V/Pa) -> Fireface (signal*0.2044) -> Recorded voltage
% Target = 130 dB amplitude / 3.16 Pa (20*log10(3.16Pa/0.000001Pa) = 130 dB re: 1 uPa)
% 316 mV peak (0.316 V) when hydrophone amplifier is set to 100 mV/Pa
% (i.e, 20*log10(3.16Pa/0.000001Pa) = 130 dB re: 1 uPa)
% The equivalent reading on the FireFace should be 0.316 * 0.2044 = 0.0646

%% Define variables
addpath(genpath("\\wsl$\ubuntu\home\aoih\adapt_aep\src\matlab"))
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
electrode_idx = find(strcmp(input_channel_names, 'Ch'));
output_channels = ex.info.recording.DAC_output_channels;
hydrophone_voltage_scaling_factor_V = ex.info.recording.hydrophone_voltage_scaling_factor_V;

ex.calibration.initial_calibration_complete = 0;
ex.calibration.check_passed = 0;

%% Initialize hardware
try
    fprintf('Initializing hardware')
    % D/A converter
    ex = init_dac(ex);
    ex = test_latency(ex);
    % Audio hardware
    ex = init_audio(ex);
    % Check that other hardware is on and uses the right settings
    check_hardware_on   
catch ME
    % Display what went wrong
    fprintf(2, 'ERROR during hardware initialization: %s\n', ME.message);
    fprintf(2, 'Error occurred in: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    % Re-throw the error so the calling function knows it failed
    rethrow(ME);
end

fprintf('Starting calibration...')

%% Create stimuli
% Create calibration stimulus (Send to speaker)
pre_pause = zeros(1,fs*0.1); % 100 ms pause vector
post_pause = zeros(1,fs*0.5); % 500 ms pause vector
calibration_stim = [pre_pause waveform post_pause];
calibration_stim = repmat(calibration_stim,10,1);

% Create trigger stimulus (Send to loopback, allows measurment of system latency)
waveform_with_trig = waveform; % Force first sample to 1 as trigger
waveform_with_trig(1) = 1;
trigger_stim = [pre_pause waveform_with_trig post_pause];
trigger_stim = repmat(trigger_stim,10,1);

%% Scale stimuli amplitude
% Begin with an output voltage of 0.01, equivalent to ~40 dB of headroom
% Fireface output = 5*digital value
base_level = 10^((target_level-170)/20);
calibration_stim = base_level.*calibration_stim; % start 40 dB down from fs, but ensure that 0.01 associated voltage is waaay below the max output of the speaker

% Measure calibration stimuli
[hydrophone_rms_dB, rec_data_mV, mean_hydrophone_sig] = ...
measure_calibration_stimuli( ...
    calibration_stim, trigger_stim, waveform, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, loopback_idx, ...
    hydrophone_voltage_scaling_factor_V, stimulus_freq, ramp_duration_ms, fs);

%% Save values
ex.calibration.initial_calibration_complete = 1;
ex.calibration.uncorrected_levels = hydrophone_rms_dB;
correction_factor_dB = target_level-hydrophone_rms_dB;
ex.calibration.correction_factor_dB = correction_factor_dB;
ex.calibration.correction_factor_linear = 10.^(correction_factor_dB/20);
ex.calibration.signals = rec_data_mV;

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


%% Check if stimulus amplitude is within range with correction factor
fprintf('Correction factor = %.3f dB. Now checking correction factor effectiveness.', correction_factor_dB)

% Apply new correction factor
target_calibration_stim = ex.calibration.correction_factor_linear*calibration_stim; % calibration_stim already includes headroom (i.e., multiplication of 0.01), %# does 0.01 get incorporated in the calculation for correction factor later?

% Measure calibration stimuli
[hydrophone_rms_dB, rec_data_mV, mean_hydrophone_sig] = ...
measure_calibration_stimuli( ...
    target_calibration_stim, trigger_stim, waveform, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, loopback_idx, ...
    hydrophone_voltage_scaling_factor_V, stimulus_freq, ramp_duration_ms, fs);

%% Save values
ex.calibration.corrected_level = hydrophone_rms_dB;

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

%% Decide if calibration factor is sufficient
if ex.calibration.corrected_level >= target_level-correction_tolerance_dB && ...
        ex.calibration.corrected_level <= target_level+correction_tolerance_dB % If correction factor worked
    
    ex.calibration.check_passed = 1;
    fprintf('Target level = %.1f +/- %.1f \nCorrected level = %.1f. Effective calibration factor identified. Calibration complete.\n', ...
        target_level, correction_tolerance_dB, hydrophone_rms_dB)
    
    % Save calibration file
    ex.calibration.signals = rec_data_mV;    
    filename_root = app.ex.info.animal.filename_root;
    time_stamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename = strcat(filename_root, '_calibration_',time_stamp); %# have it save to data/calibration folder
    ex.info.calibration.file_name = filename;

    calibration = ex.calibration;
    save(filename, 'calibration')

else
    fprintf(['Target level = %.1f +/- %.1f \nCorrected level = %.1f. Correction factor ineffective.' ...
        'Investigate tank acoustic environment further before reattempting calibration\n'], ...
        target_level, correction_tolerance_dB, hydrophone_rms_dB)
end
end

