%% summary_plot_hydro_acoustics
% T_hydro
% 1f
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
for ifreq = 1:length(freq_inc)
    cur_color = select_chan_color(ifreq);
    nexttile
    T_sub = T_hydro(T_hydro.Freq == freq_inc(ifreq),:);
    [uniq_sub, ~] = unique(T_sub.Subj_ID);
    n_uniq_sub = numel(uniq_sub);
    [ga, amps_u] = findgroups(T_sub.Amp);
    nsubj = splitapply(@(x) numel(unique(x)),T_sub.Subj_ID,ga);

    boxchart(T_sub.Amp, T_sub.OFF_1f, ...
        'BoxFaceColor', [0.6 0.6 0.6], 'MarkerColor', [0.9 0.9 0.9], ...
        'BoxFaceAlpha', 0.25,'BoxEdgeColor', [0.75 0.75 0.75], 'WhiskerLineColor', [0.75 0.75 0.75])
    hold on
    boxchart(T_sub.Amp, T_sub.ON_1f, ...
        'BoxFaceColor', cur_color, 'MarkerColor', cur_color)

    text(amps_u, repmat(20,size(amps_u)), string(nsubj), ...
        'HorizontalAlignment','center', 'FontSize', 8, 'Color',tableau_10('grey'));

    xlim([min(T_sub.Amp)-3 max(T_sub.Amp)+3])
    xticks(unique(T_sub.Amp))
    title(sprintf('%d Hz N = %d', freq_inc(ifreq),n_uniq_sub))
    xlabel('Assigned Stimulus Amplitude (dB)')
    if ifreq == 1
        ylabel('Amplitude at Stimulus Frequency (dB)')
    end
end
linkaxes(findall(gcf,'Type','axes'),'xy')
sgtitle('Stimulus and Noise Floor Amplitude at Stimulus Frequency')

% 30 Hz
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
for ifreq = 1:length(freq_inc)
    cur_color = select_chan_color(ifreq);
    nexttile
    T_sub = T_hydro(T_hydro.Freq == freq_inc(ifreq),:);
    [uniq_sub, ~] = unique(T_sub.Subj_ID);
    n_uniq_sub = numel(uniq_sub);
    [ga, amps_u] = findgroups(T_sub.Amp);
    nsubj = splitapply(@(x) numel(unique(x)),T_sub.Subj_ID,ga);

    boxchart(T_sub.Amp, T_sub.OFF_30Hz, ...
        'BoxFaceColor', [0.6 0.6 0.6], 'MarkerColor', [0.9 0.9 0.9], ...
        'BoxFaceAlpha', 0.25,'BoxEdgeColor', [0.75 0.75 0.75], 'WhiskerLineColor', [0.75 0.75 0.75])
    hold on
    boxchart(T_sub.Amp, T_sub.ON_30Hz, ...
        'BoxFaceColor', cur_color, 'MarkerColor', cur_color)

    text(amps_u, repmat(20,size(amps_u)), string(nsubj), ...
        'HorizontalAlignment','center', 'FontSize', 8, 'Color',tableau_10('grey'));

    xlim([min(T_sub.Amp)-3 max(T_sub.Amp)+3])
    xticks(unique(T_sub.Amp))
    title(sprintf('%d Hz N = %d', freq_inc(ifreq),n_uniq_sub))
    xlabel('Assigned Stimulus Amplitude (dB)')
    if ifreq == 1
        ylabel('Amplitude at Stimulus Frequency (dB)')
    end
end
linkaxes(findall(gcf,'Type','axes'),'xy')
sgtitle('Stimulus and Noise Floor Amplitude at 30 Hz')