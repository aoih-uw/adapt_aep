function [n_trials, n_samples, ...
    output_channels, input_channels, ...
    DAC_conversion_factor, bioamp_factor, accel_amp_factor,...
    hydrophone_idx, loopback_idx, electrode_idx, accel_idx] ...
        = init_present_sound_variables(ex, stimulus_block)
%% Initializes all of the variables needed for running present_sound function
% Channel metadata
n_trials = height(stimulus_block);
n_samples = length(stimulus_block(1,:)');
output_channels = ex.info.DAC.output_channels;
input_channels = ex.info.DAC.input_channels;
input_channel_names = ex.info.DAC.input_channel_names;

% Indexes
hydrophone_idx = find(strcmp(input_channel_names, 'Hydrophone'));
loopback_idx = find(strcmp(input_channel_names, 'Loopback'));
if ex.test_accel
    accel_idx = find(ismember(input_channel_names, ex.info.accel.chan_order));
    electrode_idx = find(startsWith(input_channel_names, 'Ch'));
else
    accel_idx = []; % not needed
    electrode_idx = find(startsWith(input_channel_names, 'Ch'));
end

% Conversion factors
DAC_conversion_factor = ex.info.DAC.conversion_factor;
bioamp_factor = ex.info.bio_amp.gain;
accel_amp_factor = ex.info.accel.amp_gain;

end