function rec_data_mV = present_sound(stimulus, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, ...
    electrode_voltage_scaling_factor_V, ...
    hydrophone_voltage_scaling_factor_V)
%% Here we actually present and measure sounds
signal_clip_threshold = 4850; %mv
%% Pre-allocate for efficiency
rec_data_mV = zeros(size(stimulus,2), ...
    length(input_channels), size(stimulus,1)); % # of samples x # of channels x # of trials

for itrial = 1:height(stimulus)
    % Progress bar
    if itrial == 1, fprintf('\n'); end
    pct = itrial / height(stimulus);
    bar = repmat('█', 1, round(pct * 20));
    gap = repmat('░', 1, 20 - round(pct * 20));
    fprintf('\r  %s%s %d/%d (%.0f%%)', bar, gap, itrial, height(stimulus), pct*100);
    if itrial == height(stimulus), fprintf('\n  Finished\n'); end

    % Get current trial
    if size(stimulus,3) > 1 % We have signals to present on more than one channel
        current_waveform = squeeze(stimulus(itrial,:,:));
    else % Only one channel we have signals to present
        current_waveform = stimulus(itrial,:)';
        current_waveform = [current_waveform current_waveform]; % Give a signal to loopback too!
    end
    
    % Check amplitude range for safety (prevent speaker/electrode damage)
    max_amplitude = max(abs(current_waveform));
    amplitude_threshold = 1.0; % Adjust based on your system's safe range
    if max_amplitude > amplitude_threshold
        error('\nStimulus %d amplitude too high (%.3f): exceeds safety threshold (%.3f)\n', ...
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

    % Convert digital values to millivolts - ALL channels
    rec_data_mV(:,:,itrial) = rec_data;

    % Check for clipped signals
    for ichan = 1:length(input_channels)
            cur_sig = rec_data(:,ichan);
            if any(cur_sig >= signal_clip_threshold)
                fprintf('Possible clipping. Inspect signal.')
                keyboard
            end
        
    end

    % Apply specific scaling factors and convert to mV
    rec_data_mV(:,electrode_idx,itrial) = 1e3.*(rec_data(:,electrode_idx).*electrode_voltage_scaling_factor_V);
    rec_data_mV(:,hydrophone_idx,itrial) = 1e3.*(rec_data(:,hydrophone_idx).*hydrophone_voltage_scaling_factor_V);
    
    % Check for absurdly large electrode signals
    if any(abs(rec_data_mV(:)) > 1e4)
        [y, Fs] = audioread('error.mp3');
            sound(y, Fs)
        fprintf('\nUnusually large voltage values detected in sensors (max: %.2f mV)\n', ...
            max(abs(rec_data_mV(:))));
        pause(2)
    end
    
end

rec_data_mV = permute(rec_data_mV,[3,1,2]); % change to n_trial, n_sample, n_channel