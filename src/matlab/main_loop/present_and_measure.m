function ex = present_and_measure(ex,app)
% OUTPUT = ex.raw.electrodes (n_trials x n_samples x n_channels)

% Load in variables
fs = ex.info.recording.sampling_rate_hz;
iamp = ex.counter.iamp;
iblock = ex.counter.iblock;
stimulus_block = ex.block(iblock).stimulus_block;
trials_per_block = ex.info.adaptive.trials_per_block;
N_trials_presented = iblock*trials_per_block;
color_names = {'blue', 'orange', 'red', 'teal', 'green', 'yellow', 'purple', 'pink', 'brown', 'grey'};

[ex, n_channels, n_trials, n_samples, output_channels, ...
    input_channels, hydrophone_idx, loopback_idx, electrode_idx, ...
    electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
        = init_present_and_measure_vars(ex, stimulus_block);

% Preallocate variables
ex.raw(iblock).hydrophone = zeros(n_trials, n_samples);
ex.raw(iblock).loopback = zeros(n_trials, n_samples);
ex.raw(iblock).electrodes = zeros(n_trials, n_samples, n_channels);

% Rip it
if ex.test
    rec_data_mV = ex.mock_data;
else
    rec_data_mV = present_sound(stimulus_block, ...
        input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, ...
        electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V);
end

% Save values to ex
ex.raw(iblock).hydrophone = squeeze(rec_data_mV(:,:,hydrophone_idx));
ex.raw(iblock).loopback  = squeeze(rec_data_mV(:,:,loopback_idx));
ex.raw(iblock).electrodes  = rec_data_mV(:,:,electrode_idx); % n_trials, n_samples, n_channels
ex.raw(iblock).time_stamp = datetime('now');
ex.trial_count(iamp) = N_trials_presented;

%% Update GUI
app.Label_number_trials_presented.Text = string(N_trials_presented);

time_s = (0:n_samples-1) / fs;

% Plot hydrophone
cla(app.UIAxes_hydrophone); % Plot random single trial since taking the mean will cancel out the stimulus...
hold(app.UIAxes_hydrophone, 'on'); 
plot(app.UIAxes_hydrophone, time_s, ex.raw(iblock).hydrophone(randperm(n_trials,1), :),'Color',tableau_10('purple'),'LineWidth',1.5);
hold(app.UIAxes_hydrophone, 'off');
title(app.UIAxes_hydrophone, 'Hydrophone');

% Plot electrode channels
electrode_axes = {app.UIAxes_ch1, app.UIAxes_ch2, app.UIAxes_ch3, app.UIAxes_ch4};

for ch = 1:n_channels
    cla(electrode_axes{ch});
    hold(electrode_axes{ch}, 'on');
    
    % Compute mean and std across trials
    data_mean = mean(squeeze(ex.raw(iblock).electrodes(:, :, ch)), 1);
    data_std = std(squeeze(ex.raw(iblock).electrodes(:, :, ch)), 0, 1);
    
    % Get color for this channel
    color = tableau_10(color_names{mod(ch-1, 10) + 1});
    
    % Plot shaded area for +/- 1 std
    fill(electrode_axes{ch}, [time_s, fliplr(time_s)], ...
         [data_mean + data_std, fliplr(data_mean - data_std)], ...
         color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    
    % Plot mean
    plot(electrode_axes{ch}, time_s, data_mean, 'Color', color, 'LineWidth', 1.5);
    
    hold(electrode_axes{ch}, 'off');
end