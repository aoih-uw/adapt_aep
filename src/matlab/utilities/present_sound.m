function [rec_data_mV, ex] = present_sound(stimulus, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, ...
    electrode_voltage_scaling_factor_V, ...
    hydrophone_voltage_scaling_factor_V, ex, app)
%% This function calls playrec to simultaneously present and record signals. Presents signals trial by trial, 
% shows progress for number of trials presented per batch, enters debugging state when playrec gets stuck, 
% checks for clipped hydrophone signals and absurdly high amplitude values,
% applies correction factors to recover true mV values from electrodes/hydrophone after being amplified and processed by the DAC

% Assign variables
signal_clip_threshold = 4.5; % V
%% Pre-allocate for efficiency
rec_data_mV = zeros(size(stimulus,2), ...
    length(input_channels), size(stimulus,1)); % # of samples x # of channels x # of trials

t_rate = tic();
for itrial = 1:height(stimulus)
    % Get current trial
    if size(stimulus,3) > 1 % We have signals to present on more than one channel
        current_waveform = squeeze(stimulus(itrial,:,:));
    elseif size(stimulus,3) == 1 % Only one channel we have signals to present
        current_waveform = stimulus(itrial,:)';
        current_waveform = repmat(current_waveform, 1, length(output_channels)); % Replicate signal to all output channels
    end

    % Check amplitude range for safety (prevent speaker/electrode damage)
    max_amplitude = max(abs(current_waveform(:)));
    amplitude_threshold = 1.0; % Adjust based on your system's safe range
    if max_amplitude > amplitude_threshold
        error('\nStimulus %d amplitude too high (%.3f): exceeds safety threshold (%.3f)\n', ...
            itrial, max_amplitude, amplitude_threshold);
    end

    % Rip it
    try
        ipage = playrec('playrec', current_waveform, output_channels, -1, input_channels);
        
        % Timeout guard
        t0 = tic;
        while ~playrec('isFinished', ipage)
            if toc(t0) > 20
                playrec('delPage', ipage);
                if strcmp(app.DropDown_test_mode.Value, 'Mixed stimuli')
                    ex = save_mixed_raw(ex,app);
                else
                    if isfield(ex.info.experiment,'amp_time_start')
                        ex = save_single_raw(ex, app, false);
                    end
                end
                keyboard % Don't allow the program to progress further now since ex.block structure has been reset after saving
            error('Playrec timed out. Check USB cord connection')
            end
        end
        pause(0.05);

        % Get recorded data
        rec_data = double(playrec('getRec', ipage));

        % Clean up the page
        playrec('delPage', ipage);

    catch ME
        % Clean up on error
        if exist('ipage','var'), playrec('delPage', ipage); end
        error('Audio recording failed for stimulus %d: %s', itrial, ME.message);
    end

    % Check for clipped hydrophone signals
    cur_sig = rec_data(:,hydrophone_idx); % rec_data is in Volts
    post_bioamp_sig = cur_sig.*hydrophone_voltage_scaling_factor_V; % Undo the scaling that the DAC did to understand what values it recieved
    if any(abs(post_bioamp_sig) >= signal_clip_threshold)
        fprintf('Possible clipping in hydrophone signal. Inspect signal.\n')
        keyboard % Inspect signal and progress when issue is solved
    end

    % Apply specific scaling factors and convert to mV
    rec_data_mV(:,:,itrial) = rec_data;
    rec_data_mV(:,electrode_idx,itrial) = 1e3.*(rec_data(:,electrode_idx).*electrode_voltage_scaling_factor_V);
    rec_data_mV(:,hydrophone_idx,itrial) = 1e3.*(rec_data(:,hydrophone_idx).*hydrophone_voltage_scaling_factor_V);

    % Check for absurdly large electrode signals
    if any(abs(rec_data_mV(:,:,itrial)) > 1e3, 'all')
        fprintf('\nUnusually large voltage values detected in sensors (max: %.2f mV)\n', ...
        max(abs(rec_data_mV(:,:,itrial)), [], 'all'));
        keyboard
    end

    fprintf('.');
    if itrial == height(stimulus), fprintf('\n  Finished\n'); end
end

% Measure presentation rate
my_dur = toc(t_rate);
trials_per_sec = height(stimulus)/my_dur;
fprintf('Presentation rate: %.2f trials/sec\n', trials_per_sec);

% Rearrange data
rec_data_mV = permute(rec_data_mV,[3,1,2]); % change to n_trial, n_sample, n_channel