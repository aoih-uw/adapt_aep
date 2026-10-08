%% summary_plot_2f_consistency
figure;
tiledlayout(1,3,'TileSpacing','tight','Padding','tight')

for ifreq = 1:numel(freq_inc)
    nexttile
    tmp = T_slope(T_slope.Freq == freq_inc(ifreq),:);
    boxchart(tmp.Amp, tmp.Slope, 'GroupByColor',tmp.Chan)
    title(sprintf('%d Hz', freq_inc(ifreq)));
    xlabel('Stimulus Amplitude (dB SPL)')
    ylabel('Slope (\muV / Min)')
    yline(0,'--')
end
legend({'Subcranial','Subcutaneous'}, 'Location','northwest', 'Box','off')
sgtitle('Does 2f response stay stable across test?')