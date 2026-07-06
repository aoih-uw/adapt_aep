function ex  = run_calibrate_stimulus(app, ex)
%% Main calibration script for adapt_aep
%% Information
% Fireface Correction Factor
% Stimulus sound pressure (Pa) -> Hydrophone measurement -> Amplifier (100 mV/Pa or 0.1 V/Pa) -> Fireface (signal*0.2044) -> Recorded voltage
% Target = 130 dB SPL: re: 1 uPa = (20*log10(3.16Pa/0.000001Pa)
% 3.16 Pa RMS = 3.16* sqrt(2) = 4.47 Pa peak amplitude
% 316 mV peak (0.316 V) when hydrophone amplifier is set to 100 mV/Pa
% The equivalent reading on the FireFace should be 0.316 * 0.2044 = 0.0646

%% Define variables
fs = ex.info.recording.sampling_rate_hz;
target_freq_range = ex.info.stimulus.range_2f_hz;

cal = ex.info.calibration;
stimulus_freq = ex.info.stimulus.frequency_hz;
target_level = ex.info.calibration.target_amp_spl;
waveform = ex.info.stimulus.waveform; % When using optimize signal quality function

correction_tolerance_dB = ex.info.calibration.correction_tolerance_dB;

cal.initial_calibration_complete = 0;
cal.check_passed = 0;

max_attempts = 3;

%% Create stimuli
% Create calibration stimulus (Send to speaker)
stim_OFF_pause = zeros(1,fs*0.1); % 100 ms pause vector
post_pause = zeros(1,fs*0.5); % 500 ms pause vector
calibration_stim = [stim_OFF_pause waveform post_pause];

% Create trigger stimulus (Send to loopback, allows measurment of system latency)
waveform_with_trig = waveform; % Force first sample to 1 as trigger
waveform_with_trig(1) = 1;
trigger_stim = [stim_OFF_pause waveform_with_trig post_pause];

%% Scale stimuli amplitude
% Begin with an output voltage of 0.01, equivalent to ~40 dB of headroom
% Fireface output = 5*digital value
base_level = calculate_base_level(target_level);
calibration_stim = base_level.*calibration_stim; % start 40 dB down from fs, but ensure that 0.01 associated voltage is waaay below the max output of the speaker

% Measure calibration stimuli
[hydrophone_rms_dB, ~, mean_hydrophone_sig, ex] = ...
    measure_calibration_stimuli(ex, calibration_stim, trigger_stim, waveform,...
    stimulus_freq, fs, app);

%% Save values
cal.initial_calibration_complete = 1;
cal.uncorrected_levels = hydrophone_rms_dB;
correction_factor_dB = target_level-hydrophone_rms_dB;
cal.correction_factor_dB = correction_factor_dB;
cal.correction_factor_linear = 10.^(correction_factor_dB/20);

%% Update GUI PLots
% Update labels
app.label_uncorr_level.Text = sprintf('%1.1f',hydrophone_rms_dB);
app.label_corr_factor.Text = sprintf('%1.1f',correction_factor_dB);

% Time domain
n_samples = length(mean_hydrophone_sig);
time_vector = (0:n_samples-1)/fs;
plot(app.ax_hydrophone, time_vector, mean_hydrophone_sig)

% Frequency domain
[~, freq_vec, fft_vals] = calc_fft(mean_hydrophone_sig,fs);
plot(app.ax_hydrophone_spectra, freq_vec,fft_vals)
xlim(app.ax_hydrophone_spectra, [0, 1000])

% Measure signal quality
selected_idx = freq_vec > 1 & freq_vec < 5000;
freq_vec = freq_vec(selected_idx);
fft_vals = fft_vals(selected_idx);
my_snr = calculate_fft_snr(fft_vals, freq_vec, stimulus_freq, target_freq_range, 0);
app.label_snr.Text = sprintf('%1.1f',my_snr);

drawnow;

%% Check if stimulus amplitude is within range with correction factor
fprintf('\nCorrection factor = %.3f dB. Now checking correction factor effectiveness.\n', correction_factor_dB)

% Apply new correction factor
target_calibration_stim = cal.correction_factor_linear*calibration_stim;

% Measure calibration stimuli
[hydrophone_rms_dB, rec_data_mV, mean_hydrophone_sig, ex] = ...
    measure_calibration_stimuli(ex, target_calibration_stim, trigger_stim, waveform,...
    stimulus_freq, fs, app);

%% Save values
cal.signals = rec_data_mV;
cal.corrected_level = hydrophone_rms_dB;

%% Update GUI
% Update labels
app.label_corr_level.Text = sprintf('%1.1f',hydrophone_rms_dB);

% Time domain
n_samples = length(mean_hydrophone_sig);
time_vector = (0:n_samples-1)/fs;
plot(app.ax_hydrophone, time_vector, mean_hydrophone_sig)

% Frequency domain
[~, freq_vec, fft_vals] = calc_fft(mean_hydrophone_sig,fs);
plot(app.ax_hydrophone_spectra, freq_vec,fft_vals)

% Measure signal quality
selected_idx = freq_vec > 1 & freq_vec < 5000;
freq_vec = freq_vec(selected_idx);
fft_vals = fft_vals(selected_idx);
my_snr = calculate_fft_snr(fft_vals, freq_vec, stimulus_freq, target_freq_range, 0);
app.label_snr.Text = sprintf('%1.1f',my_snr);

drawnow;

% Save data to ex
cal.time_vector = time_vector;
cal.time_sig = mean_hydrophone_sig;
cal.freq_vec = freq_vec;
cal.fft_vals = fft_vals;
cal.snr = my_snr;

% Initialize attempt counter only on first call
if ~isfield(cal, 'attempt')
    cal.attempt = 0;
end

%% Decide if calibration factor is sufficient
if cal.corrected_level >= target_level-correction_tolerance_dB && ...
        cal.corrected_level <= target_level+correction_tolerance_dB % If correction factor worked

    cal.check_passed = 1;
    fprintf('\nTarget level = %.1f +/- %.1f \nCorrected level = %.3f \nEffective calibration factor identified. Calibration complete.\n', ...
        target_level, correction_tolerance_dB, hydrophone_rms_dB)

else
    fprintf(['\nTarget level = %.1f +/- %.1f \nCorrected level = %.1f\n Correction factor ineffective.' ...
        'Investigate tank acoustic environment further before reattempting calibration\n'], ...
        target_level, correction_tolerance_dB, hydrophone_rms_dB)

    cal.attempt = cal.attempt + 1;

    if cal.attempt < max_attempts
        ex.info.calibration.attempt = cal.attempt;
        ex = run_calibrate_stimulus(app, ex);
        % Set back to 0 to allow another 3 tries
        ex.info.calibration.attempt = 0;
        return
    else
        fprintf('Max attempts reached.\n')
    end
end

ex.info.calibration = cal;

end

