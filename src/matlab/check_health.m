function ex = check_health(ex, app)
ex.counter.health = ex.counter.health + 1;
stimulus_block = ex.health.waveforms;

% Present sound and measure response
electrode_voltage_scaling_factor_V = ex.info.recording.electrode_voltage_scaling_factor_V;
hydrophone_voltage_scaling_factor_V = ex.info.recording.hydrophone_voltage_scaling_factor_V;
output_channels = ex.info.recording.DAC_output_channels;
input_channels = ex.info.recording.DAC_input_channels;
input_channel_names = ex.info.recording.DAC_input_channel_names;

n_channels = ex.info.channels.n_channels;
n_trials = height(stimulus_block);
n_samples = length(stimulus_block(1,:)');

electrode_idx = find(startsWith(input_channel_names, 'Ch')); % Assign index values for playrec output
ex.health(iblock).electrodes = zeros(n_channels, n_samples, n_trials); % Preallocate variables

rec_data_mV = present_sound(stimulus, ...
    input_channels, output_channels, ...
    electrode_idx, hydrophone_idx, ...
    electrode_voltage_scaling_factor_V, hydrophone_voltage_scaling_factor_V);

electrode_data_mV  = rec_data_mV(:,:,electrode_idx)';

% Preprocess signal

% Analyze signal

% Determine if response strength has changed
x_vec = 1:ex.counter.health; 
y_vec = zeros(1,ex.counter.iblock);

% Fit linear regression
p = polyfit(x_vec, y_vec, 1);      % p(1) = slope, p(2) = intercept

plot(app.health_ax, x_vec, y_vec)
hold(app.health_ax, 'on')
plot(app.health_ax, x_vec, polyval(p, x_vec), 'r--')
xlabel(app.health_ax, 'Check point')
ylabel(app.health_ax, 'Double Freq. Response Mag.')

rel_strength = y_vec(end)/max(y_vec); % find the relative strength of the last check to the highest response

% Decide
if rel_strength > 0.8
    ex.health(1).status = 'good';
elseif rel_strength > 0.5
    ex.health(1).status = 'fair';
else
    ex.health(1).status = 'poor';
    ex = health_dialog(ex);
end