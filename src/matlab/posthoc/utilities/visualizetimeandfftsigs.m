%% Plot raw signals
fs = 44100;
n_trials = 5;
amp_idx = find([ex_save.block_level_info.stim_freq] == 100);
freq_idx = find(ismember([ex_save.block_level_info(amp_idx).stim_amp],[95 110 125]));
my_idx = amp_idx(freq_idx);

for iidx = 1:numel(my_idx)
    % Time domain
    figure;tiledlayout(n_trials,2,"TileSpacing","tight","Padding","tight")
    cur_idx = my_idx(iidx);
    cur_freq = ex_save.block_level_info(cur_idx).stim_freq;
    cur_amp = ex_save.block_level_info(cur_idx).stim_amp;
    ax_time = gobjects(n_trials,1);
    ax_fft = gobjects(n_trials,1);
    for itrial = 1:n_trials
        cur_sig = ex_save.raw_signals(cur_idx).electrodes_microV(itrial,:,2);
        ax_time(itrial) = nexttile;
        x_vec = (0:length(cur_sig)-1)./fs;
        plot(x_vec,cur_sig,'Color',tableau_10('blue')) % subcranial electrode only

        % Calculate freq domain
        [~, freq_vec, fft_vals] = calc_fft(cur_sig,fs);
        ax_fft(itrial) = nexttile;
        plot(freq_vec,fft_vals, 'Color',tableau_10('blue'))
        xlim([100 300])
        title(sprintf('%g',itrial))
    end
    sgtitle( sprintf('%d Hz | %d dB SPL | Batch # %g', cur_freq, cur_amp,cur_idx))
    linkaxes(ax_time); linkaxes(ax_fft)
end
