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

hydrophone_voltage_scaling_factor_V = ex.info.recording.hydrophone_voltage_scaling_factor_V;

output_channels = ex.info.recording.DAC_output_channels;

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
catch
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
calibration_stim = 0.01.*calibration_stim; % start 40 dB down from fs, but ensure that 0.01 associated voltage is waaay below the max output of the speaker

% Measure calibration stimuli
[hydrophone_rms_dB, rec_data_mV] = measure_calibration_stimuli( ...
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

% Update GUI PLots
fprintf('Correction factor = %.3f dB. Now checking correction factor effectiveness.', correction_factor_dB)

%% Check if stimulus amplitude is within range with correction factor
% Apply new correction factor
target_calibration_stim = ex.calibration.correction_factor_linear*calibration_stim; % calibration_stim already includes base level 130 dB (i.e., multiplication of 0.01), %# does 0.01 get incorporated in the calculation for correction factor later?

% Measure calibration stimuli
[hydrophone_rms_dB, rec_data_mV] = measure_calibration_stimuli( ...
    calibration_stim, trigger_stim, waveform, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, loopback_idx, ...
    hydrophone_voltage_scaling_factor_V, stimulus_freq, ramp_duration_ms, fs);

% Save values
ex.calibration.corrected_level = hydrophone_rms_dB;

if ex.calibration.corrected_level >= target_level-correction_tolerance_dB || ...
        ex.calibration.corrected_level <= target_level+correction_tolerance_dB % If correction factor worked
    ex.calibration.check_passed = 1;
    fprintf('Target level = %.1f +/- %.1f \nCorrected level = %.1f. Effective calibration factor identified. Calibration complete.\n', ...
        target_level, correction_tolerance_dB, hydrophone_rms_dB)
    % Save calibration file
    ex.info.calibration.file_name = filename;

elseif ex.calibration.corrected_level < target_level-correction_tolerance_dB || ...
        ex.calibration.corrected_level > target_level+correction_tolerance_dB % If correction factor didn't work
end



end

