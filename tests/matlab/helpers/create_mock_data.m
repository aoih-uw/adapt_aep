function mock_data = create_mock_data(ex, signal_scaling, noise_scaling)
% Make sure that make_stim_block uses a 170 dB stimulus amplitude as the
% baseline

my_signals = ex.block(end).stimulus_block;
[n_trials,n_samples] = size(my_signals);
my_noises = pinknoise(n_trials, n_samples);
scale_to_1_rms = 1/rms(my_noises(1,:));
my_noises = my_noises*scale_to_1_rms;

% Apply scaling
my_signals = my_signals*signal_scaling;
my_noises = my_noises*noise_scaling;
mock_data = my_signals+my_noises;
mock_data = repmat(mock_data, [1,1,length(ex.info.recording.DAC_input_channel_names)]);

end



