function [n_channels, n_trials, n_samples, ...
    output_channels, input_channels, ...
    DAC_conversion_factor, bioamp_factor, accel_amp_factor,...
    hydrophone_idx, loopback_idx, electrode_idx, accel_idx] ...
        = init_present_sound_variables(ex, stimulus_block)
%% Initializes all of the variables needed for running present_sound function
% Channel metadata
n_channels = ex.info.channels.n_channels;
n_trials = height(stimulus_block);
n_samples = length(stimulus_block(1,:)');
output_channels = ex.info.recording.DAC_output_channels;
input_channels = ex.info.recording.DAC_input_channels;
input_channel_names = ex.info.recording.DAC_input_channel_names;

% Indexes
hydrophone_idx = find(strcmp(input_channel_names, 'Hydrophone'));
loopback_idx = find(strcmp(input_channel_names, 'Loopback'));
electrode_idx = find(startsWith(input_channel_names, 'Ch'));
accel_idx = find(ismember(ex.info.recording.DAC_input_channels, ...
    ex.info.accel.DAC_input_channels(3:end)));

% Conversion factors
DAC_conversion_factor = ex.info.recording.DAC_conversion_factor;
bioamp_factor = ex.info.recording.bioamp_gain;
accel_amp_factor = ex.info.accel.amp_gain;

end