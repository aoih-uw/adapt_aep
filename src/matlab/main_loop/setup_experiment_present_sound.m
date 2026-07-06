function ex = setup_experiment_present_sound(ex,app)
%% Handles setup of variables needed for running present_sound() and saves raw signals to ex structure
% OUTPUT = ex.raw.electrodes_microV(N_trials x N_samples x N_channels)
% ex.trial_count gets updated here

% Load in variables
iblock = ex.counter.iblock;
trials_per_block = ex.info.trials.trials_per_block;
stimulus_block = ex.block(iblock).stimulus_block;
fs = ex.info.recording.sampling_rate_hz;
if strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli') || strcmp(app.DropDown_test_mode.Value, 'Timed')
    N_trials_presented = ex.counter.grand_iblock*trials_per_block;
    if strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
        first_block = iblock - ex.counter.N_not_enough_trials;
    end
else
    N_trials_presented = iblock*trials_per_block;
end
if ~strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
    iamp = ex.counter.iamp;
end

% Get necessary metadata for present_sound()
[ex, N_channels, N_trials, N_samples, output_channels, ...
    input_channels, hydrophone_idx, loopback_idx, electrode_idx, ...
    electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
        = init_present_sound_variables(ex, stimulus_block);

% Rip it
if ex.test
    rec_data_mV = ex.mock_data;
    N_samples = size(rec_data_mV,2);
else
    [rec_data_mV, ex] = present_sound(stimulus_block, ...
        input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, ...
        electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V, ex, app);
end

% Save values to ex
if size(rec_data_mV,1) > 1
    % Check if there are enough slots in ex.raw
    if iblock > ex.info.trials.max_block
        idx = ex.info.trials.max_block + (1:10); % Add 10 more slots
        [ex.block(idx)] = deal(ex.template.block);
        [ex.raw(idx)] = deal(ex.template.raw);
        ex.info.trials.max_block = idx(end);
    end
    ex.raw(iblock).hydrophone_mV = squeeze(rec_data_mV(:,:,hydrophone_idx));
    ex.raw(iblock).loopback  = squeeze(rec_data_mV(:,:,loopback_idx));
    ex.raw(iblock).electrodes_microV  = rec_data_mV(:,:,electrode_idx).*1e3; % N_trials, N_samples, N_channels
    ex.raw(iblock).time_stamp = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    else
    keyboard
    error('Only 1 or less trials included in present_sound() output')
end

% Assign trial counts
if ~strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
    ex.trial_count(iamp) = N_trials_presented;
end

%% Check for NaNs
cellfun(@(v,t) check_for_nans(v,t), ...
    {ex.raw(iblock).hydrophone_mV, ex.raw(iblock).loopback}, ...
    {'signal','signal'}, ...
     'UniformOutput',false); % UniformOutput false = don't collect outputs
for ich = 1:size(ex.raw(iblock).electrodes_microV, 3)
    check_for_nans(ex.raw(iblock).electrodes_microV(:,:,ich), 'signal')
end

%% Calculate hydrophone RMS dB SPL
if mod(iblock,10) == 0 || iblock == 1 % Only do this every 10 blocks since this is computationally heavy
    tic()
    fprintf('Calculating hydrophone SNR and tank noise floor...\n')
    ex = calculate_hydrophone_sig_quality(ex);
    toc()
end

%% Plot signals
tic()
plot_sigs_to_monitor('raw',ex,app,N_samples,N_trials,N_channels)
toc()
if strcmp(app.DropDown_test_mode.Value, 'Timed') || strcmp(app.DropDown_test_mode.Value, 'Static trial count')
    plot_live_fft(ex, iblock, fs, app)
end

%% Update GUI
if strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
    app.Label_number_trials_presented.Text = string((iblock-first_block+1)*trials_per_block);
else
    app.Label_number_trials_presented.Text = string(N_trials_presented);
end
time_since_exp_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.info.experiment.exp_time_start;
time_elapsed =  string(time_since_exp_start, 'hh:mm:ss');
app.Label_time_elapsed.Text = time_elapsed;
ex.info.experiment.total_time_elapsed = time_since_exp_start;
if strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
    app.Label_grand_total.Text = string(N_trials_presented);
else
    grand_total_N_trials = sum(arrayfun(@(x) x, ex.trial_count(1:ex.counter.iamp)));
    app.Label_grand_total.Text = string(grand_total_N_trials);
end

%% Play sound after every present_sound() attempt has been completed
[y, Fs] = audioread('batch.mp3');
sound(y, Fs)


