function ex = present_and_measure(ex,app)
% OUTPUT = ex.raw.electrodes_microV(N_trials x N_samples x N_channels)

% Load in variables
iamp = ex.counter.iamp;
iblock = ex.counter.iblock;
stimulus_block = ex.block(iblock).stimulus_block;
trials_per_block = ex.info.adaptive.trials_per_block;
N_trials_presented = iblock*trials_per_block;

[ex, N_channels, N_trials, N_samples, output_channels, ...
    input_channels, hydrophone_idx, loopback_idx, electrode_idx, ...
    electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
        = init_present_and_measure_vars(ex, stimulus_block);

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

%% Check for full NaN rows in raw data
hydrophone_nan = any(all(isnan(ex.raw(iblock).hydrophone_mV), 2));
loopback_nan = any(all(isnan(ex.raw(iblock).loopback), 2));

% For 3D electrode data, check each channel independently
for ich = 1:size(ex.raw(iblock).electrodes_microV, 3)
    electrode_nan = any(all(isnan(ex.raw(iblock).electrodes_microV(:,:,ich)), 2));
    if electrode_nan
        fprintf('NaN rows found in electrode channel %d\n', ich);
        keyboard
    end
end

if hydrophone_nan || loopback_nan
    fprintf('NaN rows found - hydrophone: %d, loopback: %d\n', ...
        hydrophone_nan, loopback_nan);
    keyboard
end

% Save values to ex
ex.raw(iblock).hydrophone_mV = squeeze(rec_data_mV(:,:,hydrophone_idx));
ex.raw(iblock).loopback  = squeeze(rec_data_mV(:,:,loopback_idx));
ex.raw(iblock).electrodes_microV  = rec_data_mV(:,:,electrode_idx).*1e3; % N_trials, N_samples, N_channels
ex.raw(iblock).time_stamp = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.trial_count(iamp) = N_trials_presented;



%% Update GUI
app.Label_number_trials_presented.Text = string(N_trials_presented);
time_since_exp_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.info.experiment.exp_time_start;
app.Label_time_elapsed.Text = string(time_since_exp_start, 'hh:mm:ss');
grand_total_N_trials = sum(arrayfun(@(x) x, ex.trial_count(1:ex.counter.iamp)));
app.Label_grand_total.Text = string(grand_total_N_trials);

%% Plot signals
plot_to_monitor('raw',ex,app,N_samples,N_trials,N_channels)
