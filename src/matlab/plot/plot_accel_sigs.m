function plot_accel_sigs(ex,app)
%% Get vars
iblock = ex.counter.iblock;
n_chans = 3;
accel_dB = [];
fs = ex.info.recording.sampling_rate_hz;
my_colors = [tableau_10('red'); tableau_10('blue'); tableau_10('orange');tableau_10('teal')];

% Get current stimulus_info
freq_idx = get_current_freq_idx(ex);
cur_freq = ex.info.stimulus(freq_idx).frequency_hz;
cur_amp = ex.block(iblock).stim_amp;

% Sample lengths
latency_samples = ex.info.recording.latency_samples;
period_length_samples = length(ex.info.stimulus(freq_idx).waveform);
ramp_duration_ms = ex.info.stimulus(freq_idx).ramp_duration_ms;
ramp_duration_samples = round(ramp_duration_ms/1000*fs);
jitter_vec = ex.block(iblock).phase_vec;

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

%% Plot FFT (Just from the last set of sig_set)
ax = app.UIAxes_live_fft;
% Clear axes
delete(findobj(ax, 'Type', 'text'));
% PLot
for i = 1:size(sig_set,1)
[~,freq_vec,fft_vals] = calc_fft(sig_set(i,:),fs);
plot(ax,freq_vec,fft_vals,'Color',my_colors(i,:),'LineWidth',1.5)
hold(ax,'on');
end
xlim(ax,[1 500])
title(ax,'Accelerometer FFT')
xlabel(ax,'Frequency (Hz)')
ylabel(ax,'Amplitude (mV)')
hold(ax,'off');

%% Plot dB values across 10 trials
ax = app.UIAxes_funfetti;
% Clear axes
delete(findobj(ax, 'Type', 'text'));

% Setup data
x_data = {'X', 'Y', 'Z', 'All'};
x_data = categorical(x_data, x_data);
% Get per dimension and all dimension data into one variable
y_data = median(micro_m_per_s_sqrd_set,2);
err_data = mad(micro_m_per_s_sqrd_set,1,2);

% Plot
b = bar(ax,x_data,y_data,'FaceColor','flat');
hold(ax,'on')
errorbar(ax,x_data,y_data,err_data,'k','LineStyle','none')
hold(ax,'off')

% Formatting
b.CData = my_colors;
xlabel(ax,'Dimension');
ylabel(ax,'Acceleration (dB re: 1\mum/s^2)')
title(ax,sprintf('Accelerometer %d Hz | %d dB SPL',cur_freq,cur_amp))
end