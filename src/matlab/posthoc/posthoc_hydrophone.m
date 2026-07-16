fs = 22050;
period_length_samples =  length(ex_save.info.stimulus.waveform)/2;
ramp_duration_samples = ex_save.info.stimulus.ramp_duration_ms*fs
signal = ex_save.raw_signals(1).electrodes_microV_ds(:,:,4);
phase_vec = ex_save.block_level_info.phase_vec;
for itrial = 1:size(signal,1)
    figure;
    tiledlayout(2,1,"TileSpacing",'tight','Padding','tight')
    cur_phase = phase_vec(itrial);
    cur_trial = signal(itrial,:);

    [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
    signal, isONOFF, fs, ...
    2118, period_length_samples, ramp_duration_samples,...
    5,...
    cur_phase)

    [~,freq_vec,fft_val] = calc_fft(cur_trial,fs);
    nexttile
    plot(((0:length(cur_trial)-1)./fs),cur_trial)
    nexttile
    plot(freq_vec,fft_val)
    xlim([0,200])
end

