function [ex, rec_data_mV] = measure_EKG(ex)
fs = ex.info.recording.sampling_rate_hz;
stimulus_block = zeros(1,fs*15); % Take 1 15 second reading of the EKG
% Get present_sound_variables
[ex, N_channels, N_trials, N_samples, output_channels, input_channels, ...
    hydrophone_idx, ~, electrode_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
    = init_present_sound_variables(ex, stimulus_block);

redo = true;
while redo
    fprintf('Please wait 15 seconds ...')
    [rec_data_mV, ekg_sig] = run_ekg(stimulus_block, input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V);
    % Plot signal
    myfig = figure;
    t = (0:N_samples-1) / fs;
    plot(t, squeeze(ekg_sig(1,:,1)), 'k-', 'LineWidth', 0.5);
    xlabel('Time (s)'); ylabel('EKG (\muV)');
    title('EKG Recording — Confirm Signal Quality');
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