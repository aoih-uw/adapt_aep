function mock_data = create_mock_data(ex, signal_scaling, noise_scaling)
    my_signals = ex.block(end).stimulus_block;
    [n_trials, n_samples] = size(my_signals);
    period_length = length(ex.info.stimulus.waveform);
    my_noise = zeros(size(my_signals,1), size(my_signals,2));
    my_pink_noise = pinknoise(n_trials, period_length);
    latency_samples = ex.info.recording.latency_samples;
    jitter_samples = ex.block(end).jitter;
    
    for itrial = 1:n_trials
        pre_start = jitter_samples(itrial) + latency_samples + 1;
        pre_end = pre_start + period_length - 1;
        dur_start = pre_end + 1;
        dur_end = dur_start + period_length - 1;
        
        % Add same pink noise to both pre and dur periods
        my_noise(itrial, pre_start:pre_end) = my_pink_noise(itrial, :);
        my_noise(itrial, dur_start:dur_end) = my_pink_noise(itrial, :);
    end
    
    scale_to_1_rms = 1/rms(my_noise(1,:));
    my_noise = my_noise * scale_to_1_rms;
    
    % Apply scaling
    my_signals = my_signals * signal_scaling;
    my_noise = my_noise * noise_scaling;
    
    mock_data = my_signals + my_noise;
    mock_data = repmat(mock_data, [1, 1, length(ex.info.recording.DAC_input_channel_names)]);
end