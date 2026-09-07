% Categories are metadata they dont get removed when you filter the data
rf_T.Chan = mergecats(rf_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
thresh_T.Chan = mergecats(thresh_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
elec_inc = ["Subcutaneous", "Subcranial"];
freq_inc = [55, 100, 410];

% Advanced heatmap version
%% HEATMAP
sub = rf_T(rf_T.CI == 99 ...
    & rf_T.Boot_It_N == 5000 ...
    & ismember(rf_T.Chan,elec_inc) ...
    & ismember(rf_T.Freq,freq_inc),:);
sub.Chan = removecats(sub.Chan);
freqs = unique(sub.Freq);
% sub.Val(sub.Val==260,:) = NaN;
all_the_amps = unique(sub.Amp);
allAmps = string(all_the_amps);

sub.Val(sub.Val==260,:) = NaN;
ampVals = unique(sub.Amp);
chans   = categories(sub.Chan);
G = groupsummary(sub,{'Freq','Chan','Amp'},{'median',@(x) mad(x,1)},'Val');
G.Properties.VariableNames(end-1:end) = {'med','madv'};
cmap = interp1([0 1],[1 1 1; tableau_10('blue')],linspace(0,1,256));

figure;
tiledlayout(3,1,'TileSpacing','tight','Padding','tight')
for ifreq = 1:length(freqs)
    sub_2 = sub(sub.Freq == freqs(ifreq),:);
    g = G(G.Freq == freqs(ifreq),:);
    M = nan(numel(chans),numel(ampVals)); D = M;
    [~,r] = ismember(string(g.Chan),string(chans));
    [~,c] = ismember(g.Amp,ampVals);
    idx = sub2ind(size(M),r,c);
    M(idx) = g.med;  D(idx) = g.madv; D(D == 0) = NaN;

    nexttile;
    imagesc(M,'AlphaData',~isnan(M));
    colormap(gca,cmap); clim([0 max(G.med)]);
    set(gca,'Color',tableau_10('grey'),'TickLength',[0 0], ...
        'XTick',1:numel(ampVals),'XTickLabel',ampVals, ...
        'YTick',1:numel(chans),'YTickLabel',chans);
    for i = find(~isnan(M))'
        [rr,cc] = ind2sub(size(M),i);
        if M(i) ~= 10
            text(cc,rr-0.15,sprintf('%.0f',M(i)),'HorizontalAlignment','center','FontSize',12);
        end
        if ~isnan(D(i))
            text(cc,rr+0.22,sprintf('%.0f',D(i)),'HorizontalAlignment','center','FontSize',6,'Color',[.4 .4 .4]);
        end
    end
    title(sprintf('%d Hz N = %d',freqs(ifreq),length(unique(sub_2.Subj_ID))))
end

%% Threshold Box plot
exclude_subj = [34];
exclude_freq_for_subj = [55];
sub = thresh_T(ismember(thresh_T.Chan,elec_inc) ...
    & ismember(thresh_T.Freq,freq_inc) ...
    & ~(ismember(thresh_T.Subj_ID,exclude_subj) & ismember(thresh_T.Freq,exclude_freq_for_subj)),:);
sub.Chan = removecats(sub.Chan);
N = groupsummary(sub,{'Freq','Chan'},'numunique','Subj_ID');
figure;
colororder([tableau_10('blue'); tableau_10('orange')])
boxchart(categorical(sub.Freq), sub.Threshold,'GroupByColor', sub.Chan)
xlabel('Frequency (Hz)'); ylabel('Threshold (dB SPL)')
title('AEP Threshold Estimation')
legend

%% Low CI Fit plot




%% Reference code %%

% Line plot version
figure;
tiledlayout(3,1,'TileSpacing','tight','Padding','tight')
for ifreq = 1:length(freqs)
    cur_color = select_chan_color(ifreq);
    sub_2 = sub(sub.Freq == freqs(ifreq),:);
    [g,amps] = findgroups(sub_2.Amp);
    m = splitapply(@median,sub_2.Val,g);
    e = splitapply(@(v) mad(v,1), sub_2.Val, g);
    nexttile;
    p = errorbar(amps,m,e,'O-','Color',cur_color,'LineWidth',2,'MarkerFaceColor',cur_color);
    xlim([min(all_the_amps) max(all_the_amps)])
    xticks(all_the_amps)
    xticklabels(all_the_amps)
    title(sprintf('%d Hz N = %d',freqs(ifreq), length(unique(sub_2.Subj_ID))))
    ylabel('N Trials Needed to detect')
    xlabel('Stimulus Amplitude (dB)')
end

% Heatmap version
sub.Val(sub.Val==260,:) = NaN;
figure;
tiledlayout(3,1,'TileSpacing','tight','Padding','tight')
for ifreq = 1:length(freqs)
    sub_2 = sub(sub.Freq == freqs(ifreq),:);
    nexttile;
    h = heatmap(sub_2,'Amp','Chan', 'ColorVariable','Val', 'ColorMethod', 'median');
    h.CellLabelFormat = '%.0f';
    h.MissingDataColor = tableau_10('grey');
    h.ColorbarVisible = 'off';
    h.Colormap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
    h.XDisplayData = allAmps;
    title(sprintf('%d Hz',freqs(ifreq)))
end