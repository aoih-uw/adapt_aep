function rec_data_mV = present_sound(stimulus, input_channels, output_channels, voltage_scaling_factor_V)
rec_data_mV = zeros(size(stimulus,2), ...
    length(input_channels), size(stimulus,1)); % Pre-allocate for efficiency

for itrial = 1:height(stimulus)
    current_waveform = stimulus(itrial,:)';

    % Check amplitude range for safety (prevent speaker/electrode damage)
    max_amplitude = max(abs(current_waveform));
    amplitude_threshold = 1.0; % Adjust based on your system's safe range
    if max_amplitude > amplitude_threshold
        error('Stimulus %d amplitude too high (%.3f): exceeds safety threshold (%.3f)', ...
            itrial, max_amplitude, amplitude_threshold);
    end

    % Rip it
    try
        ipage = playrec('playrec', current_waveform, output_channels, -1, input_channels);

        % Wait for recording to complete
        playrec('block', ipage);

        % Get recorded data
        rec_data = double(playrec('getRec', ipage));

        % Clean up the page
        playrec('delPage', ipage);
    catch ME
        % Clean up on error
        try
            playrec('delPage', ipage);
        catch
            % Ignore cleanup errors
        end
        error('Audio recording failed for stimulus %d: %s', itrial, ME.message);
    end

    % Convert digital values to microvolts
    rec_data_mV(:,:,itrial) = 1e6*(rec_data.*voltage_scaling_factor_V);
    % Check for absurdly large electrode signals
    if any(abs(rec_data_mV(:)) > 1e6)
        warning('Unusually large voltage values detected in electrode signal (max: %.2f µV)', ...
            max(abs(rec_data_mV(:))));
    end
end