function ex = setup_experiment_present_sound(ex,app)
% OUTPUT = ex.raw.electrodes_microV(N_trials x N_samples x N_channels)

% Load in variables
iamp = ex.counter.iamp;
iblock = ex.counter.iblock;
stimulus_block = ex.block(iblock).stimulus_block;
trials_per_block = ex.info.adaptive.trials_per_block;
N_trials_presented = iblock*trials_per_block;
fs = 44100;

[ex, N_channels, N_trials, N_samples, output_channels, ...
    input_channels, hydrophone_idx, loopback_idx, electrode_idx, ...
    electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
        = init_present_sound_variables(ex, stimulus_block);

% Rip it
if ex.test
    rec_data_mV = ex.mock_data;
    N_samples = size(rec_data_mV,2);
    % Preallocate variables
    ex.raw(iblock).hydrophone_mV= zeros(N_trials, N_samples);
    ex.raw(iblock).loopback = zeros(N_trials, N_samples);
    ex.raw(iblock).electrodes_microV = zeros(N_trials, N_samples, N_channels);
else
    rec_data_mV = present_sound(stimulus_block, ...
        input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, ...
        electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V);
    % Preallocate variables
    ex.raw(iblock).hydrophone_mV= zeros(N_trials, N_samples);
    ex.raw(iblock).loopback = zeros(N_trials, N_samples);
    ex.raw(iblock).electrodes_microV = zeros(N_trials, N_samples, N_channels);
end

% Save values to ex
ex.raw(iblock).hydrophone_mV = squeeze(rec_data_mV(:,:,hydrophone_idx));
ex.raw(iblock).loopback  = squeeze(rec_data_mV(:,:,loopback_idx));
ex.raw(iblock).electrodes_microV  = rec_data_mV(:,:,electrode_idx).*1e3; % N_trials, N_samples, N_channels
ex.raw(iblock).time_stamp = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.trial_count(iamp) = N_trials_presented;

% Plot funfetti figures
if strcmp(app.DropDown_test_mode.Value, 'Timed') || strcmp(app.DropDown_test_mode.Value, 'Static trial count')
    plot_funfetti(ex, iblock, fs, app)
end

%% Update GUI
app.Label_number_trials_presented.Text = string(N_trials_presented);
time_since_exp_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.info.experiment.exp_time_start;
time_elapsed =  string(time_since_exp_start, 'hh:mm:ss');
app.Label_time_elapsed.Text = time_elapsed;
ex.info.experiment.total_time_elapsed = time_since_exp_start;
grand_total_N_trials = sum(arrayfun(@(x) x, ex.trial_count(1:ex.counter.iamp)));
app.Label_grand_total.Text = string(grand_total_N_trials);

%% Check for NaNs
cellfun(@(v,t) check_for_nans(v,t), ...
    {ex.raw(iblock).hydrophone_mV, ex.raw(iblock).loopback}, ...
    {'signal','signal'}, ...
     'UniformOutput',false); % UniformOutput false = don't collect outputs

for ich = 1:size(ex.raw(iblock).electrodes_microV, 3)
    check_for_nans(ex.raw(iblock).electrodes_microV(:,:,ich), 'signal')
end

if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
    %% Calculate hydrophone RMS dB SPL
    ex = calculate_hydrophone_sig_quality(ex);
    % Display RMS Noise floor and stimulus amplitude onto the GUI
    app.UIAxes_hydrophone.Title.String = sprintf('Hydrophone: %.0f dB SPL',ex.block(iblock).hydrophone.stim_ON_rms_dB_spl);
end

%% Plot signals
plot_to_monitor('raw',ex,app,N_samples,N_trials,N_channels)

