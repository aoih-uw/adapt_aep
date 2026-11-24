%% Plot the selected sigs
close all
fs = 44100;
ax = gobjects(3,2);
figure;
tiledlayout(3,2,'TileSpacing','tight','Padding','tight')
for i = 3:-1:1
ax(i,1) = nexttile;
cur_sig = sig_set{i};
x_vec = (0:length(cur_sig)-1)/fs;

plot(x_vec,cur_sig,'Color',tableau_10('blue'),'LineWidth',1)
hold on;
xline((length(waveform)+2118+jit_set(i))/fs)
xline((length(waveform)*2+2118+jit_set(i))/fs)
xline(2118/fs)
title(string(amp_vec(i)))
xlim([0 0.75])

[stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
    cur_sig, 1, fs, ...
    2208, length(waveform), round((60/1000)*fs),...
    0,...
    jit_set(i));

[~, freq_vec, fft_vec] = calc_fft(stim_ON,fs);

ax(i,2) = nexttile;
plot(freq_vec,fft_vec,'Color',tableau_10('blue'),'LineWidth',2)

hold on;

[~, freq_vec, fft_vec] = calc_fft(stim_OFF,fs);
plot(freq_vec,fft_vec,'Color',tableau_10('orange'),'LineWidth',2)

xlim([140 260])
end

linkaxes(ax(:,1))
linkaxes(ax(:,2))