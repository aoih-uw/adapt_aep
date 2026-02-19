function [ex, mock_data] = create_mock_data(ex, signal_scaling, noise_scaling)
    iblock = ex.counter.iblock;
    if iblock > 1
        ex.block(iblock).stimulus_block = ex.block(1).stimulus_block; % Just use the first set of signals you made, as you will apply scaling later on here
        ex.block(iblock).jitter = ex.block(1).jitter;
        ex.block(iblock).phase_vec = ex.block(1).phase_vec;
    end
    my_signals = ex.block(iblock).stimulus_block; 
    [n_trials, n_samples] = size(my_signals);
    my_noise = pinknoise(size(my_signals,1), size(my_signals,2));
    
    scale_to_1_rms = 1/rms(my_noise(1,:));
    my_noise = my_noise * scale_to_1_rms;
    
    % Apply scaling
    my_signals = my_signals * signal_scaling;
    my_noise = my_noise * noise_scaling;
    
    mock_data = my_signals + my_noise;
    mock_data = repmat(mock_data, [1, 1, length(ex.info.recording.DAC_input_channel_names)]);
end