function [ex, cal]  = run_calibrate_stimulus(app, ex, recording_info, stimulus_info, cal)
%% Main calibration script for adapt_aep
%% Information
% Fireface Correction Factor
% Stimulus sound pressure (Pa) -> Hydrophone measurement -> Amplifier (100 mV/Pa or 0.1 V/Pa) -> Fireface (signal*0.2044) -> Recorded voltage
% Target = 130 dB SPL: re: 1 uPa = (20*log10(3.16Pa/0.000001Pa)
% 3.16 Pa RMS = 3.16* sqrt(2) = 4.47 Pa peak amplitude
% 316 mV peak (0.316 V) when hydrophone amplifier is set to 100 mV/Pa (have
% been using 3.16 mV / Pa)
% The equivalent reading on the FireFace should be 0.316 * 0.2044 = 0.0646
% ex.test_acce
%% Define variables
% Recording
fs = recording_info.sampling_rate_hz;

% Stimulus
stimulus_freq = stimulus_info.frequency_hz;
waveform = stimulus_info.waveform; % When using optimize signal quality function
waveform = waveform(:).'; % Ensure row
target_freq_range = stimulus_info.range_2f_hz;

% Calibration
target_level = cal.target_amp_spl;
correction_tolerance_dB = cal.correction_tolerance_dB;
cal.initial_calibration_complete = 0;
cal.check_passed = 0;

%% Create stimuli
% NO alternating polarity imposed since taking the average would cancel out
% Create calibration stimulus (Send to speaker)
stim_OFF_pause = zeros(1,fs*0.1); % 100 ms pause vector
post_pause = zeros(1,fs*0.5); % 500 ms pauseF vector
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
rec_data_mV =  measure_calibration_stimuli(ex, calibration_stim, trigger_stim);

% Filter, correct, and calculate dB
[hydro_rms_dB, accel_dB, ...
    mean_hydrophone_sig, mean_accel_sigs_mV] = calc_calibration_dB(ex, rec_data_mV, waveform, recording_info, stimulus_info, ex.test_accel);

%% Store values
% Uncorrected values
cal.initial_calibration_complete = 1;
cal.uncorrected_hydro_dB = hydro_rms_dB;
cal.uncorrected_accel_dB = accel_dB;

% Calculate correction factors
correction_factor_dB = target_level-hydro_rms_dB;
cal.correction_factor_dB = correction_factor_dB;
cal.correction_factor_linear = 10.^(correction_factor_dB/20);

%% Update GUI
% Update labels
app.label_uncorr_level.Text = sprintf('%1.1f',hydro_rms_dB);
app.label_corr_factor.Text = sprintf('%1.1f',correction_factor_dB);
[time_vector,app,cal] = plot_hydro(cal,mean_hydrophone_sig,fs,app,stimulus_freq,target_freq_range);
% Plot accelerometer data if active
if ex.test_accel
    plot_accel(mean_accel_sigs_mV,time_vector,ex,accel_dB)
end

%% Check if stimulus amplitude is within range with correction factor
fprintf('\nCorrection factor = %.3f dB. Now checking correction factor effectiveness.\n', correction_factor_dB)

% Apply new correction factor
target_calibration_stim = cal.correction_factor_linear*calibration_stim;
if max(abs(target_calibration_stim)) > 1
    error('Corrected stimulus clips (peak %.2f); reduce target level.', max(abs(target_calibration_stim)))
end

% Measure calibration stimuli
rec_data_mV = measure_calibration_stimuli(ex, target_calibration_stim, trigger_stim);

% Filter, correct, and calculate dB
[hydro_rms_dB, accel_dB, ...
    mean_hydrophone_sig, mean_accel_sigs_mV] = calc_calibration_dB(ex, rec_data_mV, waveform, recording_info, stimulus_info, ex.test_accel);

%% Save values
cal.signals = rec_data_mV;
cal.corrected_hydro_dB = hydro_rms_dB;
cal.corrected_accel_dB = accel_dB;

%% Update GUI
% Update labels
app.label_corr_level.Text = sprintf('%1.1f',hydro_rms_dB);
[time_vector,app,cal] = plot_hydro(cal,mean_hydrophone_sig,fs,app,stimulus_freq,target_freq_range);
% Plot accelerometer signal if active
if ex.test_accel
    plot_accel(mean_accel_sigs_mV,time_vector,ex,accel_dB);
end

%% Decide if calibration factor is sufficient
if cal.corrected_hydro_dB >= target_level-correction_tolerance_dB && ...
        cal.corrected_hydro_dB <= target_level+correction_tolerance_dB % If correction factor worked
    cal.check_passed = 1;
    fprintf('\nTarget level = %.1f +/- %.1f \nCorrected level = %.3f \nEffective calibration factor identified.\n', ...
        target_level, correction_tolerance_dB, hydro_rms_dB)

else
    fprintf(['\nTarget level = %.1f +/- %.1f \nCorrected level = %.1f\n Correction factor ineffective.' ...
        'Investigate tank acoustic environment further before reattempting calibration\n'], ...
        target_level, correction_tolerance_dB, hydro_rms_dB)
    keyboard
    return
end
end

%% Local Functions
function [time_vector,app,cal] = plot_hydro(cal,mean_hydrophone_sig,fs,app,stimulus_freq,target_freq_range)
% Time domain
n_samples = length(mean_hydrophone_sig);
time_vector = (0:n_samples-1)/fs;
plot(app.ax_hydrophone, time_vector, mean_hydrophone_sig,'Color',tableau_10('blue'),'LineWidth',1.5)

% Frequency domain
[~, freq_vec, fft_vals] = calc_fft(mean_hydrophone_sig,fs);
plot(app.ax_hydrophone_spectra, freq_vec,fft_vals,'Color',tableau_10('blue'),'LineWidth',1.5)
xlim(app.ax_hydrophone_spectra, [0, stimulus_freq*5])

% Measure signal quality
selected_idx = freq_vec > 1 & freq_vec < 5000;
freq_vec = freq_vec(selected_idx);
fft_vals = fft_vals(selected_idx);
my_snr = calculate_fft_snr(fft_vals, freq_vec, stimulus_freq, target_freq_range, 0);
app.label_snr.Text = sprintf('%1.1f',my_snr);
drawnow;

%% Save data to cal
cal.time_vector = time_vector;
cal.time_sig = mean_hydrophone_sig;
cal.freq_vec = freq_vec;
cal.fft_vals = fft_vals;
cal.snr = my_snr;
end

function plot_accel(mean_accel_sigs_mV,time_vector,ex,accel_dB)
my_colors = [tableau_10('red'); tableau_10('blue'); tableau_10('orange');tableau_10('purple')];
fig = figure;
tiledlayout(fig,1,size(mean_accel_sigs_mV,1)+1,'TileSpacing','tight','Padding','tight')
% Time domain signal
for i = 1:size(mean_accel_sigs_mV,1)
    nexttile
    plot(time_vector, mean_accel_sigs_mV(i,:),'Color',my_colors(i,:),'LineWidth',1.5);
    hold on;
    title(ex.info.accel.DAC_input_channel_names{2+i})
    xlabel('Time (s)')
    ylabel('Amplitude (mV)')
end

% Compare individual dimensions acceleration (micro metres per second^2)
nexttile
x_data = {'X', 'Y', 'Z', 'All'};
x_data = categorical(x_data, x_data);
% Get per dimension and all dimension data into one variable
y_data = [accel_dB.per_dim.micro_m_per_s_sqrd(:); accel_dB.all_dim.micro_m_per_s_sqrd];
b = bar(x_data,y_data,'FaceColor','flat');
b.CData = my_colors;
xlabel('Dimension');
ylabel('Acceleration (dB re: 1\mum/s^2)')

% Set main figure title
sgtitle('Accelerometer')

% Let the experimenter look at the data
pause(3)

if isvalid(fig), close(fig); end
end