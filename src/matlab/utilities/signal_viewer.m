function signal_viewer(signal,fs)
% signal (n_trial x n_samples)
% fs sampling rate
figure;
tiledlayout(2,1,'TileSpacing','tight','Padding','tight')
nexttile
for itrial = 1:size(signal,1)
    cur_sig = signal(itrial,:);
    t_vec = (0:(length(cur_sig)-1))/fs;
    plot(t_vec,cur_sig);
    title(sprintf('%d',itrial))
    drawnow
    pause(0.1)

end
xlabel('Time (s)')
ylabel('Amplitude')

% Frequency domain
nexttile
for itrial = 1:size(signal,1)
    cur_sig = signal(itrial,:);
    [~,freq_vec, fft_vals] = calc_fft(cur_sig,fs);
    plot(freq_vec,fft_vals);  
    hold on
    xlim([0 800])
end

xlabel('Frequency (Hz)')
ylabel('Amplitude')
title('Frequency Domain')
