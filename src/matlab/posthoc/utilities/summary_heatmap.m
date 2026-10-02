%% summary_heatmap
% Filter dataset
sub_T = T_rf(T_rf.CI == 99 ...
    & T_rf.Boot_It_N == 5000 ...
    & ismember(T_rf.Chan,chan_inc) ...
    & ismember(T_rf.Freq,freq_inc),:);
sub_T.Chan = removecats(sub_T.Chan);
[~, chan, freq, amp] = findgroups(sub_T.Chan, sub_T.Freq, sub_T.Amp);
freqs = unique(sub_T.Freq);
% sub_T.Val(sub_T.Val==260,:) = NaN;
all_the_amps = unique(sub_T.Amp);
allAmps = string(all_the_amps);

ampVals = unique(sub_T.Amp);
chans   = categories(sub_T.Chan);

% First hit
G = groupsummary(sub_T,{'Freq','Chan','Amp'},{'median',@(x) mad(x,1)},'First');
make_heatmap(G,freqs,sub_T,chans,ampVals, 'First Hit')

% Last stable hit
G = groupsummary(sub_T,{'Freq','Chan','Amp'},{'median',@(x) mad(x,1)},'Stable');
make_heatmap(G,freqs,sub_T,chans,ampVals, 'First Stable Hit')

function make_heatmap(G,freqs,sub_T,chans,ampVals,mytitle)
G.Properties.VariableNames(end-1:end) = {'med','madv'};
% mask = G.med == 260;
% G.med(mask) = NaN;
% G.madv(mask) = NaN;
cmap = interp1([0 1],[1 1 1; tableau_10('blue')],linspace(0,1,256));
figure;
tiledlayout(3,1,'TileSpacing','tight','Padding','tight')
for ifreq = 1:length(freqs)
    sub_2 = sub_T(sub_T.Freq == freqs(ifreq),:);
    g = G(G.Freq == freqs(ifreq),:);
    M = nan(numel(chans),numel(ampVals)); D = M;
    [~,r] = ismember(string(g.Chan),string(chans));
    [~,c] = ismember(g.Amp,ampVals);
    idx = sub2ind(size(M),r,c);
    M = nan(numel(chans),numel(ampVals)); D = M; N = M;
    M(idx) = g.med;  D(idx) = g.madv;  D(D == 0) = NaN;  N(idx) = g.GroupCount;

    nexttile;
    imagesc(M,'AlphaData',~isnan(M));
    colormap(gca,cmap); clim([0 max(G.med)]);
    set(gca,'Color',tableau_10('grey'),'TickLength',[0 0], ...
        'XTick',1:numel(ampVals),'XTickLabel',ampVals, ...
        'YTick',1:numel(chans),'YTickLabel',chans);
    for i = find(~isnan(M))'
        [rr,cc] = ind2sub(size(M),i);

        % N trials needed
        text(cc,rr-0.15,sprintf('%.0f',M(i)),'HorizontalAlignment','center','FontSize',12);
        if ~isnan(D(i))
            % MAD
            text(cc,rr+0.22,sprintf('%.0f',D(i)),'HorizontalAlignment','center','FontSize',8,'Color',[.4 .4 .4]);
        end
        % N subjects
        text(cc,rr+0.38,sprintf('%d',N(i)),'HorizontalAlignment','center','FontSize',6,'Color',[.4 .4 .4]);

    end
    title(sprintf('%d Hz',freqs(ifreq)),'FontSize',14)
end
sgtitle(mytitle)
end