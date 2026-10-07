function ex = setup_experiment_present_sound(ex,app)
%% Handles setup of variables needed for running present_sound() and saves raw signals to ex structure
% OUTPUT = ex.raw.electrodes_microV(N_trials x N_samples x N_channels)
% ex.trial_count gets updated here

%% Assign variables
iblock = ex.counter.iblock;
trials_per_block = ex.info.trials.trials_per_block;
stimulus_block = ex.block(iblock).stimulus_block;
fs = ex.info.recording.sampling_rate_hz;
test_accel = ex.test_accel;

% Get current stimulus info
freq_idx = get_current_freq_idx(ex);
stim_freq = ex.info.stimulus(freq_idx).frequency_hz;
if strcmp(app.DropDown_test_mode.Value, 'Mixed freqs')
    current_amplitude = ex.info.mixed.test_schedule(ex.counter.ischedule,3); % [stim_freq, stim_name, stim_amp, trials_needed, uniq_idx]
else
    current_amplitude = ex.info.stimulus.amplitude_spl;
end

% Identify number of trials presented up till now
if strcmp(app.DropDown_test_mode.Value, 'Mixed freqs') || ...
        strcmp(app.DropDown_test_mode.Value, 'Timed')
    N_trials_presented = ex.counter.grand_iblock*trials_per_block;
else
    N_trials_presented = iblock*trials_per_block;
end
if ~strcmp(app.DropDown_test_mode.Value, 'Mixed freqs')
    iamp = ex.counter.iamp;
end

%% Get necessary metadata for present_sound()
[~, N_trials, N_samples, ...
    output_channels, input_channels, ...
    DAC_conversion_factor, bioamp_factor, accel_amp_factor, ...
    hydrophone_idx, loopback_idx, electrode_idx, accel_idx] ...
    = init_present_sound_variables(ex, stimulus_block);

fprintf('%d Hz %d dB ', stim_freq, current_amplitude);

%% Rip it
rec_data_mV = present_sound(stimulus_block, ...
    input_channels, output_channels, ...
    hydrophone_idx, DAC_conversion_factor);

%% Apply electrode correction values and store values to ex
if size(rec_data_mV,1) > 1
    % Structure: N_trials, N_samples, N_channels
    if test_accel
        % Apply amplifier correction
        ex.raw(iblock).accelerometer_mV = rec_data_mV(:,:,accel_idx)./accel_amp_factor;
    else
        % Apply amplifier correction and convert mV -> microV
        ex.raw(iblock).electrodes_microV  = rec_data_mV(:,:,electrode_idx).*(1e3/bioamp_factor);
    end

    % Store rest of values, already corrected for DAC conversion rate in
    % present_sound so values are already in mV
    ex.raw(iblock).hydrophone_mV = squeeze(rec_data_mV(:,:,hydrophone_idx));
    ex.raw(iblock).loopback  = squeeze(rec_data_mV(:,:,loopback_idx));
    ex.raw(iblock).time_stamp = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
else
    keyboard
    error('Only 1 or less trials included in present_sound() output\n')
end

%% Check for dropped out loopback signal
for itrial = 1:size(stimulus_block,1)
    if rms(ex.raw(iblock).loopback(itrial,:)) < 1e-7
        keyboard
    end
end

%% Assign trial counts
if strcmp(app.DropDown_test_mode.Value, 'Timed')
    ex.trial_count(iamp) = iblock*trials_per_block;
end

%% Check for NaNs
cellfun(@(v,t) check_for_nans(v,t), ...
    {ex.raw(iblock).hydrophone_mV, ex.raw(iblock).loopback}, ...
    {'signal','signal'}, ...
    'UniformOutput',false); % UniformOutput false = don't collect outputs
if ex.test_accel
    for ich = 1:size(ex.raw(iblock).accelerometer_mV, 3)
        check_for_nans(ex.raw(iblock).accelerometer_mV(:,:,ich), 'signal')
    end
else
    for ich = 1:size(ex.raw(iblock).electrodes_microV, 3)
        check_for_nans(ex.raw(iblock).electrodes_microV(:,:,ich), 'signal')
    end
end

%% Calculate hydrophone RMS dB SPL
% Only do this every 10 blocks since this is computationally heavy
if mod(iblock,10) == 0 || iblock == 1
    ex = calculate_hydrophone_sig_quality(ex);
end

%% Plot signals
plot_sigs_to_monitor('raw',ex,app,N_samples,N_trials)
if strcmp(app.DropDown_test_mode.Value, 'Timed')
    plot_live_fft(ex, iblock, fs, app)
end

%% Update GUI
time_since_exp_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.info.experiment.exp_time_start;
time_elapsed =  string(time_since_exp_start, 'hh:mm:ss');
app.Label_time_elapsed.Text = time_elapsed;
ex.info.experiment.total_time_elapsed = time_since_exp_start;

%% Update command window
% Total trials presented
if strcmp(app.DropDown_test_mode.Value, 'Mixed freqs') || strcmp(app.DropDown_test_mode.Value, 'Timed')
    grand_total = N_trials_presented;
else
    grand_total = sum(ex.trial_count(1:ex.counter.iamp));
end

% Update grand total
fprintf('  %d', grand_total);
