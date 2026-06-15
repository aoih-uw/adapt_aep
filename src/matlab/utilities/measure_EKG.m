function [ex, ekg_sig_ds,ekg_rate] = measure_EKG(ex,init_check)
fs = ex.info.recording.sampling_rate_hz;

% Findpeaks vars
minDist = fs*.75; % at least a quarter of a second between
sample_dur_s = 6;
stimulus_block = zeros(1,fs*sample_dur_s); % Take 1 6 second reading of the EKG

fprintf('Please wait %d seconds ...',sample_dur_s)

% Get present_sound_variables
[ex, ~, ~, N_samples, output_channels, input_channels, ...
    hydrophone_idx, ~, electrode_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
    = init_present_sound_variables(ex, stimulus_block);

redo = true;

while redo
    [~, ekg_sig] = run_ekg(stimulus_block, input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V);

    ekg_sig = bandpassfilter(ekg_sig, 0.5, 1, 4, fs);
    peak_threshold = max(5, prctile(ekg_sig,95)); % microV % Set peak threshold by user

    % Measure spikes per second
    [pks, locs] = findpeaks(ekg_sig, 'MinPeakHeight', peak_threshold, 'MinPeakDistance', minDist);
    num_spikes = numel(pks);
    ekg_rate = (num_spikes/sample_dur_s)*60;


    % Plot signal
    myfig = figure;
    t = (0:N_samples-1) / fs;
    plot(t, squeeze(ekg_sig(1,:,1)), 'k-', 'LineWidth', 0.5);
    hold on;
    plot(t(locs), pks, 'rv', 'MarkerFaceColor', 'r');
    xlabel('Time (s)'); ylabel('EKG (\muV)');
    title(sprintf('EKG Rate: %1.0f BPM — Confirm Signal Quality', ekg_rate));
    grid on; xlim([0 t(end)]); drawnow;


    if strcmp(ex.info.experiment.exp_type,'Adaptive') || init_check || strcmp(ex.info.experiment.exp_type,'Static trial count')
        % Alert experimenter
        [y, Fs] = audioread('step.mp3'); sound(y, Fs);
        % Ask experimenter to confirm or redo
        resp = input('Press Enter to confirm, or type "r" to remeasure: ', 's');
        close(myfig);
        redo = strcmpi(strtrim(resp), 'r');
    elseif strcmp(ex.info.experiment.exp_type,'Timed')
        [y, Fs] = audioread('step.mp3'); sound(y, Fs);
        pause(3)
        close(myfig);
        redo = false;
    end
end

% Downsample concatenated signal
ekg_sig_ds = decimate(ekg_sig,3);

end


function [rec_data_mV, ekg_sig] = run_ekg(stimulus_block, input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V)
rec_data_mV = present_sound(stimulus_block, input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V);
ekg_sig = rec_data_mV(:,:,electrode_idx(1)).*1e3;
end