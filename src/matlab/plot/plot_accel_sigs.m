function plot_accel_sigs(ex,app)
%% Get vars
% Plots on live fft and accel 3d axes
iblock = ex.counter.iblock;
n_chans = 3;
accel_dB = [];
fs = ex.info.DAC.sampling_rate_hz;
my_colors = ex.info.colors;

% Get current stimulus_info
freq_idx = get_current_freq_idx(ex);
cur_freq = ex.info.stimulus(freq_idx).frequency_hz;
cur_amp = ex.block(iblock).stim_amp;

% Sample lengths
latency_samples = ex.info.DAC.latency_samples;
period_length_samples = length(ex.info.stimulus(freq_idx).waveform);
ramp_duration_ms = ex.info.stimulus(freq_idx).ramp_duration_ms;
ramp_duration_samples = round(ramp_duration_ms/1000*fs);
jitter_vec = ex.block(iblock).jitter;

% Calculate signal start/end based on per trial basis
% jitter + latency + stim OFF + onramp
start_vec = jitter_vec + latency_samples + period_length_samples + ramp_duration_samples + 1;
end_vec = start_vec + period_length_samples - (ramp_duration_samples*2) - 1;

% Get accelerometer raw data
accel_mV = ex.raw(iblock).accelerometer_mV;

%% Loop through trials
micro_m_per_s_sqrd_set = NaN(n_chans+1,size(accel_mV,1));
for itrial = 1:size(accel_mV,1)
    sig_set = [];
    for ichan = 1:n_chans
        sig_set = [sig_set; squeeze(accel_mV(itrial,start_vec(itrial):end_vec(itrial),ichan))];
    end
    accel_dB = calc_accel_dB(sig_set,ex,accel_dB);
    micro_m_per_s_sqrd_set(1:3,itrial) = accel_dB.per_dim.micro_m_per_s_sqrd;
    micro_m_per_s_sqrd_set(4,itrial) = accel_dB.all_dim.micro_m_per_s_sqrd;
end

%% Plot 3D acceleration trajectory (last trial) with dB summary
ax = app.UIAxes_accel3d;
y_data = median(micro_m_per_s_sqrd_set,2);
my_impedance = cur_amp/y_data(end);

[~, sig_ms2] = convert_mV_to_accel(sig_set, ex.info.accel.mV_per_g, ex.info.accel.mV_per_m_per_s_sqrd);
plot3(ax, sig_ms2(1,:), sig_ms2(2,:), sig_ms2(3,:), 'LineWidth', 1,'Color',tableau_10('blue'))
axis(ax,'equal'); grid(ax,'on'); view(ax,3);
xlabel(ax,'X (m/s^2)'); ylabel(ax,'Y (m/s^2)'); zlabel(ax,'Z (m/s^2)');
title(ax, sprintf('%d Hz | %d dB SPL | Impedance %.2f', cur_freq, cur_amp, my_impedance));
subtitle(ax, sprintf(['dB re 1 µm/s²: ' ...
    'X %.1f | Y %.1f | Z %.1f | All %.1f'], y_data));

%% Plot FFT on Live FFT Axes
plot_live_fft(ex, iblock, fs, app);
end