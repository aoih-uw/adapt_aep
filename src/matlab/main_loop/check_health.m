function ex = check_health(ex, app)
%% Present stimulus and measure response
% Load variables
ex.counter.health = ex.counter.health + 1;
ihealth = ex.counter.health;
stimulus_block = ex.info.health.stimulus_block;
phase_vec = ex.info.health.phase_vec;
fs = ex.info.recording.sampling_rate_hz;
color_names = {'blue', 'orange', 'red', 'teal', 'green', 'yellow', 'purple', 'pink', 'brown', 'grey'};

[ex, N_channels, N_trials, N_samples, output_channels, input_channels, ...
    hydrophone_idx, ~, electrode_idx, electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V] ...
    = init_present_and_measure_vars(ex, stimulus_block);

% Rip it
if ex.test
    rec_data_mV = ex.mock_data;
    N_samples = size(rec_data_mV,2);
    % Preallocate variables
    ex.health(ihealth).hydrophone = zeros(N_trials, N_samples);
    ex.health(ihealth).loopback = zeros(N_trials, N_samples);
    ex.health(ihealth).electrodes = zeros(N_trials, N_samples, N_channels);
else
    % Preallocate variables
    ex.health(ihealth).hydrophone = zeros(N_trials, N_samples);
    ex.health(ihealth).loopback = zeros(N_trials, N_samples);
    ex.health(ihealth).electrodes = zeros(N_trials, N_samples, N_channels);

    rec_data_mV = present_sound(stimulus_block, ...
        input_channels, output_channels, ...
        electrode_idx, hydrophone_idx, ...
        electrode_voltage_scaling_factor_V, ...
        hydrophone_voltage_scaling_factor_V);
end

% Save values to ex
ex.health(ihealth).hydrophone = squeeze(rec_data_mV(:,:,hydrophone_idx));
ex.health(ihealth).electrodes  = rec_data_mV(:,:,electrode_idx); % N_trials, N_samples, N_channels
electrode_sigs = reshape(permute(rec_data_mV(:,:,electrode_idx), [1,3,2]), [], size(rec_data_mV,2));
phase_vec = repmat(phase_vec,N_channels,1);
ex.health(ihealth).time_stamp = datetime('now');

%% Plot signals
time_s = (0:N_samples-1) / fs;
% Hydrophone
cla(app.UIAxes_hydrophone); % Plot random single trial since taking the mean will cancel out the stimulus...
hold(app.UIAxes_hydrophone, 'on'); 
plot(app.UIAxes_hydrophone, time_s, ex.health(ihealth).hydrophone(randperm(N_trials,1), :),'Color',tableau_10('purple'),'LineWidth',1.5);
hold(app.UIAxes_hydrophone, 'off');
title(app.UIAxes_hydrophone, 'Hydrophone');

% Plot electrode channels
electrode_axes = {app.UIAxes_ch1, app.UIAxes_ch2, app.UIAxes_ch3, app.UIAxes_ch4};

for ch = 1:N_channels
    cla(electrode_axes{ch});
    hold(electrode_axes{ch}, 'on');
    
    % Compute mean and std across trials
    data_mean = mean(squeeze(ex.health(ihealth).electrodes(:, :, ch)), 1);
    data_std = std(squeeze(ex.health(ihealth).electrodes(:, :, ch)), 0, 1);
    
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

%% Reject artefacts
reject_threshold_mV = ex.info.signal_quality.rejection_threshold_mV;
reject_threshold_sd = ex.info.signal_quality.rejection_threshold_sd;

% Make channel labels
all_channel_label = [];
for ichan = 1:N_channels
    all_channel_label = [all_channel_label ; ones(N_trials,1)*ichan];
end

[kept_trials_idx, ~, ~] = ...
    reject_and_balance_trials(electrode_sigs, phase_vec, ...
    reject_threshold_mV, reject_threshold_sd);

kept_trials = electrode_sigs(kept_trials_idx,:);
kept_trials_channels = all_channel_label(kept_trials_idx); % Kept_trials_channels the labels for the channels
reject_rate = ((N_trials*N_channels)-size(kept_trials,1))/(N_trials*N_channels);

if reject_rate > 0.5
    warndlg(sprintf('More than half of the health check trials have been rejected.'), 'Warning', 'Icon', 'warning');
end

fprintf('\nHealth Check artifact rejection rate: %.3f\n', reject_rate);

%% Apply channel weights
[ex, kept_trials_weighted, ~] = apply_channel_weights(ex,kept_trials,kept_trials_channels);

%% Filter signals
pass_band_hz = ex.info.signal_quality.pass_band_hz;
[ex, kept_trials_filtered] = filter_signals(ex,fs,pass_band_hz,kept_trials_weighted);

%% Calculate magnitude at 2f
if ex.test == 1
    double_freq_hz  = ex.info.stimulus.frequency_hz;
else
    double_freq_hz  = ex.info.stimulus.frequency_hz*2;
end
doub_freq_range_hz = ex.info.analysis.doub_freq_range_hz;

% Select double freq response values
lower_end = double_freq_hz - doub_freq_range_hz;
upper_end = double_freq_hz + doub_freq_range_hz;

mean_response = mean(kept_trials_filtered,1);
[~, freq_vec, fft_vec] = calc_fft(mean_response,fs);
doub_freq_mag = mean(fft_vec(:,freq_vec>= lower_end & freq_vec <= upper_end));

% Check to see if we have already measured a baseline_response for this
% animal
health_dir = fullfile(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))), 'data', 'health');
filename = fullfile(health_dir, [ex.info.health.filename_root '_health_baseline.mat']);
if ~exist(filename, 'file')
    baseline_2f_mag = doub_freq_mag;
    save(filename, 'baseline_2f_mag');
    rel_strength = 1;
    ex.health(ihealth).rel_strength = rel_strength;
    ex.info.health.baseline_response = baseline_2f_mag;

    warndlg(sprintf('The baseline 2f magnitude for this fish is: %1.4f', doub_freq_mag), 'Warning', 'modal');

else
    if isnan(ex.info.health.baseline_response)
        loaded = load(filename);
        ex.info.health.baseline_response = loaded.baseline_2f_mag;
    end
    baseline_2f_mag = ex.info.health.baseline_response;
    ex.health(ihealth).doub_stim_mag = doub_freq_mag;
    rel_strength = doub_freq_mag/baseline_2f_mag;
    ex.health(ihealth).rel_strength = rel_strength;

    % Plot
    x_vec = 1:ihealth;
    y_vec = [ex.health(1:ihealth).rel_strength];
    ax = app.UIAxes_health;
    cla(ax)
    plot(ax,x_vec,y_vec,'o-','Color',tableau_10('red'));
    hold(ax,'on')
    yline(ax,1, '--','Color',tableau_10('grey'));
    ylim(ax,[-0.2,1.2])

end

% Decide
if rel_strength > 0.8
    ex.health(ihealth).status = 'good';
elseif rel_strength > 0.5
    ex.health(ihealth).status = 'fair';
else
    ex.health(ihealth).status = 'poor';
    ex = health_dialog(ex);
end