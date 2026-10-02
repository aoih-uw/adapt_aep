%% summary_plot_hydro_acoustics

figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
sub_n = T_hydro_noise(ismember(T_hydro_noise.Freq,freq_inc),:);
sub_o = T_hydro_ON(ismember(T_hydro_ON.Freq,freq_inc),:);
for ifreq = 1:length(freq_inc)
    cur_color = select_chan_color(ifreq);
    nexttile
    nf = sub_n(sub_n.Freq == freq_inc(ifreq),:);
    on = sub_o(sub_o.Freq == freq_inc(ifreq),:);
    [uniq_sub, ~] = unique(on.Subj_ID);
    n_uniq_sub = numel(uniq_sub);
    [ga, amps_u] = findgroups(nf.Amp);
    nsubj = splitapply(@(x) numel(unique(x)),nf.Subj_ID,ga);

    boxchart(nf.Amp, nf.Val, ...
        'BoxFaceColor', [0.6 0.6 0.6], 'MarkerColor', [0.9 0.9 0.9], ...
        'BoxFaceAlpha', 0.25,'BoxEdgeColor', [0.75 0.75 0.75], 'WhiskerLineColor', [0.75 0.75 0.75])
    hold on
    boxchart(on.Amp, on.Val, ...
        'BoxFaceColor', cur_color, 'MarkerColor', cur_color)

    text(amps_u, repmat(20,size(amps_u)), string(nsubj), ...
        'HorizontalAlignment','center', 'FontSize', 8, 'Color',tableau_10('grey'));

    xlim([min(sub_n.Amp)-3 max(sub_n.Amp)+3])
    xticks(unique(sub_n.Amp))
    title(sprintf('%d Hz N = %d', freq_inc(ifreq),n_uniq_sub))
    xlabel('Assigned Stimulus Amplitude (dB)')
    if ifreq == 1
        ylabel('Amplitude at Stimulus Frequency (dB)')
    end
end
linkaxes(findall(gcf,'Type','axes'),'xy')
sgtitle('Stimulus and Noise Floor Amplitude at Stimulus Frequency')