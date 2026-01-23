function mock_data = create_mock_data(ex, snr_dB)
ex = make_tone_burst_template(ex);
ex = make_stim_block(ex);

my_signals = ex.block(end).stimulus_block;

mock_data = add_pink_noise(my_signals,snr_dB);

mock_data = repmat(mock_data, [1,1,length(ex.info.recording.DAC_input_channel_names)]);

end

function mock_data = add_pink_noise(my_signals, snr_dB)
signal_rms = rms(my_signals(:));

noise_rms_target = signal_rms/(10^(snr_dB/20));

% Generate noise
[n_trials, n_samples] = size(my_signals);
noises = pinknoise(n_trials, n_samples); % 1/f Pink noise better mimics biological noise! https://en.wikipedia.org/wiki/Pink_noise
noise_rms = rms(noises(:));

noises = noises./noise_rms; % normalize by RMS
noises = noises*noise_rms_target;

mock_data = my_signals + noises;
for itrial = 1:height(mock_data)
    plot(mock_data(itrial,:))
    hold on
end
end


