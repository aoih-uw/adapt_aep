fs = ex_save.info.recording.sampling_rate_hz;
period_length_samples = length(ex_save.info.stimulus.waveform);
ramp_duration_samples = ex_save.info.stimulus.ramp_duration_ms/1e3*fs;

figure; tiledlayout(3,1,"TileSpacing",'tight','Padding','tight')
ax1 = nexttile; hold on; title('Negative')
ax2 = nexttile; hold on; title('Positive')
ax3 = nexttile; hold on; title('Both')

for ibatch = 1:5
    cur_batch = ibatch;
    phase_vec = ex_save.block_level_info(cur_batch).phase_vec;
    neg_idx = find(phase_vec < 0);
    pos_idx = find(phase_vec > 0);

    stim_ON = [];
    for i = 1:length(neg_idx)
        cur_idx = neg_idx(i);
        cur_jitter = ex_save.block_level_info(cur_batch).jitter(cur_idx);
        cur_signal = ex_save.raw_signals(cur_batch).electrodes_microV(cur_idx,:,2);
        [stim_ON(i,:) , ~] = extract_stim_ON_OFF( ...
        cur_signal, 0, fs, ...
        2118, period_length_samples, ramp_duration_samples,...
        5,...
        cur_jitter);
    end
    [~,freq_vec, fft_vals] = calc_fft(mean(stim_ON,1),fs);
    plot(ax1,freq_vec,fft_vals,'LineWidth',2)

    stim_ON = [];
    for i = 1:length(pos_idx)
        cur_idx = pos_idx(i);
        cur_jitter = ex_save.block_level_info(cur_batch).jitter(cur_idx);
        cur_signal = ex_save.raw_signals(cur_batch).electrodes_microV(cur_idx,:,2);
        [stim_ON(i,:) , ~] = extract_stim_ON_OFF( ...
        cur_signal, 0, fs, ...
        2118, period_length_samples, ramp_duration_samples,...
        5,...
        cur_jitter);
    end
    [~,freq_vec, fft_vals] = calc_fft(mean(stim_ON,1),fs);
    plot(ax2,freq_vec,fft_vals,'LineWidth',2)

    stim_ON = [];
    for i = 1:9
        cur_jitter = ex_save.block_level_info(cur_batch).jitter(i);
        cur_signal = ex_save.raw_signals(cur_batch).electrodes_microV(i,:,2);
        [stim_ON(i,:) , ~] = extract_stim_ON_OFF( ...
        cur_signal, 0, fs, ...
        2118, period_length_samples, ramp_duration_samples,...
        5,...
        cur_jitter);
    end
    [~,freq_vec, fft_vals] = calc_fft(mean(stim_ON,1),fs);
    plot(ax3,freq_vec,fft_vals,'LineWidth',2)
end

xlim([ax1 ax2 ax3],[0 200]); ylim([ax1 ax2 ax3],[0 0.5])
xline(ax1,70); xline(ax1,130); xline(ax2,70); xline(ax2,130); xline(ax3,70); xline(ax3,130)