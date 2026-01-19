function ex = present_and_measure(ex)
% OUTPUT = ex.raw.electrodes (n_trials x n_samples x n_channels)

% Load in variables
iblock = ex.counter.iblock;
voltage_scaling_factor_V = ex.info.recording.voltage_scaling_factor_V; % Convert from digital units to voltage
stimulus_block = ex.block(iblock).stimulus_block;

n_channels = ex.info.channels.n_channels;
n_trials = height(stimulus_block);
n_samples = length(stimulus_block(1,:)');

output_channels = ex.info.recording.DAC_output_channels;
input_channels = ex.info.recording.DAC_input_channels;
input_channel_names = ex.info.recording.DAC_input_channel_names;

% Assign index values for playrec output
hydrophone_idx = find(strcmp(input_channel_names, 'Hydrophone'));
loopback_idx = find(strcmp(input_channel_names, 'Loopback'));
electrode_idx = find(startsWith(input_channel_names, 'Ch'));

% Preallocate variables
ex.raw(iblock).hydrophone = zeros(n_trials, n_samples);
ex.raw(iblock).loopback = zeros(n_trials, n_samples);
ex.raw(iblock).electrodes = zeros(n_trials, n_samples, n_channels);

% Rip it
rec_data_mV = present_sound(stimulus_block, ...
    input_channels, output_channels, voltage_scaling_factor_V);

% Save values to ex
ex.raw(iblock).hydrophone = squeeze(rec_data_mV(:,:,hydrophone_idx))';
ex.raw(iblock).loopback  = squeeze(rec_data_mV(:,:,loopback_idx))';
ex.raw(iblock).electrodes  = rec_data_mV(:,:,electrode_idx); % n_trials, n_samples, n_channels
ex.raw(iblock).time_stamp = datetime('now');

end