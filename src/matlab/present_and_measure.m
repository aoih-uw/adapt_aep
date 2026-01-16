function ex = present_and_measure(ex)
% Load in variables
iblock = ex.block(end).iteration_num+1; % +1 to index into the upcoming trial
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
ex.raw(iblock).electrodes = zeros(n_channels, n_samples, n_trials);
ex.raw(iblock).time_stamp = NaT(n_trials, 1);

for itrial = 1:height(stimulus_block)
    current_waveform = stimulus_block(itrial,:)'; 
    
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
    rec_data_mV = 1e6*(rec_data.*voltage_scaling_factor_V);
    % Check for absurdly large electrode signals
    if any(abs(rec_data_mV(:)) > 1e6)
            warning('Unusually large voltage values detected in electrode signal (max: %.2f µV)', ...
                max(abs(rec_data_mV(:))));
    end

    % Save values to ex
    ex.raw(iblock).hydrophone(itrial,:) = rec_data_mV(:,hydrophone_idx)';
    ex.raw(iblock).loopback(itrial,:)  = rec_data_mV(:,loopback_idx)';
    ex.raw(iblock).electrodes(:,:,itrial)  = rec_data_mV(:,electrode_idx)';
    ex.raw(iblock).time_stamp(itrial) = datetime('now');

end