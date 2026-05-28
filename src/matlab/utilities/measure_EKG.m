function [ex, ekg_sig, ekg_mean, ekg_rng] = measure_EKG(ex)
fs = ex.info.recording.sampling_rate_hz;

% Findpeaks vars
minDist = fs*.5; % at least a quarter of a second between
sample_dur_s = 6;
stimulus_block = zeros(1,fs*sample_dur_s); % Take 1 15 second reading of the EKG

fprintf('Please wait %d seconds ...',sample_dur_s*3)

% Get present_sound_variables
[ex, ~, ~, N_samples, output_channels, input_channels, ...
    hydrophone_idx, ~, electrode_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
    = init_present_sound_variables(ex, stimulus_block);

redo = true;
while redo    
    for i = 1:3
    [~, ekg_sig] = run_ekg(stimulus_block, input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V);

    ekg_sig = bandpassfilter(ekg_sig, 0.5, 1, 4, fs);
    ekg_sig = smoothdata(ekg_sig, 'movmean', 250);
    peak_threshold = max(5, prctile(ekg_sig,98)); % microV

    % Measure spikes per second
    [pks, locs] = findpeaks(ekg_sig, 'MinPeakHeight', peak_threshold, 'MinPeakDistance', minDist);
    num_spikes = numel(pks);
    ekg_rate(i) = (num_spikes/sample_dur_s)*60;
    end

    ekg_mean = mean(ekg_rate);
    ekg_rng = [min(ekg_rate) max(ekg_rate)];

    % Plot signal
    myfig = figure;
    t = (0:N_samples-1) / fs;
    plot(t, squeeze(ekg_sig(1,:,1)), 'k-', 'LineWidth', 0.5);
    hold on;
    plot(t(locs), pks, 'rv', 'MarkerFaceColor', 'r');
    xlabel('Time (s)'); ylabel('EKG (\muV)');
    title(sprintf('EKG Rate: %1.0f BPM %1.0f Range — Confirm Signal Quality', ekg_mean, range(ekg_rate)));
    grid on; xlim([0 t(end)]); drawnow;
    
    % Alert experimenter
    [y, Fs] = audioread('step.mp3'); sound(y, Fs);
    
    % Ask experimenter to confirm or redo
    resp = input('Press Enter to confirm, or type "r" to remeasure: ', 's');
    close(myfig);
    redo = strcmpi(strtrim(resp), 'r');
end
end

function [rec_data_mV, ekg_sig] = run_ekg(stimulus_block, input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V)
rec_data_mV = present_sound(stimulus_block, input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V);
ekg_sig = rec_data_mV(:,:,electrode_idx(1)).*1e3;
end