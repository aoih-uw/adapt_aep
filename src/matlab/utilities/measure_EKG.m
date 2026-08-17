function [ex, ekg_sig_microV_ds,ekg_rate, ekg_fs_ds, peak_threshold] = measure_EKG(ex,init_check, app)
fs = ex.info.recording.sampling_rate_hz;
%% This function uses playrec to passively measure the EKG of the subject, 
% uses findpeaks() to identify BPM rate based on a peak threshold value that the user assigns at the beginning of the experiment. 
% Depending on the testing mode, measure_EKG will ask for the user's input to inspect the signal, 
% or just show the EKG and automatically proceeds with testing.

%% Assign Variables
% Findpeaks vars
minDist = fs*.25;
sample_dur_s = 12;
stimulus_block = zeros(1,fs*sample_dur_s); % Take a 12 second reading of the EKG
ds_rate = 10;

% Get present_sound_variables
[ex, ~, ~, N_samples, output_channels, input_channels, ...
    hydrophone_idx, ~, electrode_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
    = init_present_sound_variables(ex, stimulus_block);

redo = true;

while redo
    [~, ekg_sig_microV] = run_ekg(stimulus_block, input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V);

    % Filter EKG signal
    d = designfilt('bandpassfir', 'FilterOrder', 4, ...
    'CutoffFrequency1', 1, 'CutoffFrequency2', 50, ...
    'SampleRate', fs);
    ekg_sig_microV = bandpassfilter(ekg_sig_microV, d);

    % Take absolute value of signal
    ekg_sig_microV_abs = abs(ekg_sig_microV);
    
    % Assign peak_threshold using 99 percentile
    peak_threshold = prctile(ekg_sig_microV_abs,99);
    
    % Find peaks
    [pks, locs] = findpeaks(ekg_sig_microV_abs, 'MinPeakHeight', peak_threshold, ...
        'MinPeakDistance', minDist);
    num_spikes = numel(pks);
    ekg_rate = (num_spikes/sample_dur_s)*60;

    % Plot signal
    myfig = figure;
    t = (0:N_samples-1) / fs;
    plot(t, ekg_sig_microV, 'k-', 'LineWidth', 1);
    hold on;
    plot(t(locs), pks, 'rv', 'MarkerFaceColor', 'r');
    xlabel('Time (s)'); ylabel('EKG (\muV)');
    title(sprintf('EKG Rate: %1.0f BPM — Confirm Signal Quality', ekg_rate));
    grid on; xlim([0 t(end)]); drawnow;

    % Make decison
    if strcmp(ex.info.experiment.exp_type,'Adaptive') || init_check ...
            || strcmp(ex.info.experiment.exp_type,'Static trial count')
        
        % Ask experimenter to confirm or redo
        resp = input('Press Enter to confirm, or type "r" to remeasure: ', 's');
        while ~ismember(lower(strtrim(resp)), {'', 'r'})
            resp = input('Invalid input, try again. Press Enter to confirm, or type "r" to remeasure: ', 's');
        end
        close(myfig);
        redo = strcmpi(strtrim(resp), 'r');
    elseif strcmp(ex.info.experiment.exp_type,'Timed') || strcmp(ex.info.experiment.exp_type,'Mixed freqs')
        pause(3)
        close(myfig);
        redo = false;
    end
end

% Downsample concatenated signal
ekg_sig_microV_ds = decimate(ekg_sig_microV,ds_rate);
ekg_fs_ds = fs/ds_rate;
end

%% run_ekg helper function
function [rec_data_mV, ekg_sig_microV] = run_ekg(stimulus_block, input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V)

% Present sound
[rec_data_mV]  = present_sound(stimulus_block, input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V);

% Save measurement
ekg_sig_microV = rec_data_mV(:,:,electrode_idx(1)).*1e3; % Just get the EKG channel data and convert to microV
end 