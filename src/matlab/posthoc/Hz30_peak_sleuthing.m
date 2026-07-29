downsamp_rate = 1;

fs = ex_save.info.recording.sampling_rate_hz/downsamp_rate;
period_length_samples = round(length(ex_save.info.stimulus.waveform)/downsamp_rate);
ramp_duration_samples = round(ex_save.info.stimulus.ramp_duration_ms/1e3*fs);
my_latency = 2118/downsamp_rate;
stim_freq = ex_save.info.stimulus.frequency_hz;
subject_id = ex_save.info.animal.subject_ID;

% Concatenated 
for ichan=1:4
    figure;tiledlayout(2,1,'TileSpacing','tight','Padding','tight');
    concat_vec = [];
    for i = 1:10
       concat_vec = [concat_vec ex_save.raw_signals(1).electrodes_microV(i,:,ichan)];
    end
    nexttile;plot(concat_vec);
    [~, freq_vec, fft_vals] = calc_fft(concat_vec,fs);
    nexttile;plot(freq_vec,fft_vals)
    xlim([0 250])
    sgtitle(string(ichan))
end
    % Monophasic
for ichan = 1:4
figure; tiledlayout(3,1,"TileSpacing",'tight','Padding','tight')
ax1 = nexttile; hold on; title('Negative')
ax2 = nexttile; hold on; title('Positive')
ax3 = nexttile; hold on; title('Both')

for ibatch = 1:20
    cur_batch = ibatch;
    phase_vec = ex_save.block_level_info(cur_batch).phase_vec;
    neg_idx = find(phase_vec < 0);
    pos_idx = find(phase_vec > 0);

    stim_ON = [];
    for i = 1:length(neg_idx)
        cur_idx = neg_idx(i);
        cur_jitter = round((ex_save.block_level_info(cur_batch).jitter(cur_idx))/downsamp_rate);
        cur_signal = ex_save.raw_signals(cur_batch).electrodes_microV(cur_idx,:,ichan);
        [stim_ON(i,:) , ~] = extract_stim_ON_OFF( ...
        cur_signal, 0, fs, ...
        my_latency, period_length_samples, ramp_duration_samples,...
        5,...
        cur_jitter);
    end
    [~,freq_vec, fft_vals] = calc_fft(mean(stim_ON,1),fs);
    plot(ax1,freq_vec,fft_vals,'LineWidth',1)

    stim_ON = [];
    for i = 1:length(pos_idx)
        cur_idx = pos_idx(i);
        cur_jitter = round((ex_save.block_level_info(cur_batch).jitter(cur_idx))/downsamp_rate);
        cur_signal = ex_save.raw_signals(cur_batch).electrodes_microV(cur_idx,:,ichan);
        [stim_ON(i,:) , ~] = extract_stim_ON_OFF( ...
        cur_signal, 0, fs, ...
        my_latency, period_length_samples, ramp_duration_samples,...
        5,...
        cur_jitter);
    end
    [~,freq_vec, fft_vals] = calc_fft(mean(stim_ON,1),fs);
    plot(ax2,freq_vec,fft_vals,'LineWidth',1)

    stim_ON = [];
    for i = 1:length(phase_vec)
        cur_jitter = round((ex_save.block_level_info(cur_batch).jitter(i))/downsamp_rate);
        cur_signal = ex_save.raw_signals(cur_batch).electrodes_microV(i,:,ichan);
        [stim_ON(i,:) , ~] = extract_stim_ON_OFF( ...
        cur_signal, 0, fs, ...
        my_latency, period_length_samples, ramp_duration_samples,...
        5,...
        cur_jitter);
    end
    [~,freq_vec, fft_vals] = calc_fft(mean(stim_ON,1),fs);
    plot(ax3,freq_vec,fft_vals,'LineWidth',1)
end
xlim([ax1 ax2 ax3],[0 200]); ylim([ax1 ax2 ax3],[0 0.5])
xline(ax1,stim_freq-30); xline(ax1,stim_freq+30); xline(ax2,stim_freq-30); xline(ax2,stim_freq+30); xline(ax3,stim_freq-30); xline(ax3,stim_freq+30)
sgtitle(sprintf('Subject %d %d Hz @ 140 dB SPL Channel %d', subject_id, stim_freq,ichan))
end