% Categories are metadata they dont get removed when you filter the data
rf_T.Chan = mergecats(rf_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
thresh_T.Chan = mergecats(thresh_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
chan_inc = ["Subcutaneous", "Subcranial"];
freq_inc = [55, 100, 410];

%% Low CI Fit plot
for ifreq = 1:length(freq_inc)
    figure;
    tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
    sub_T = lowCI_T(ismember(lowCI_T.Chan,chan_inc)  ...
        & lowCI_T.Freq == freq_inc(ifreq),:);
    % sub_T.Mean = low CI value of bootstrap distribution
    % sub_T.STD = num of trials needed to find response

    % Create a common grid of amplitudes
    % Find every unique combination of subjid, chan, amp, and freq
    [g, ch,amp] = findgroups(sub_T.Chan,sub_T.Amp);
    % g same height as sub_T, showing which full model fit curve that row belongs to
    % sid/ch/fr all nGroups long, sid(7), ch(7), fr(7) tell you what group 7 is

    my_median = splitapply(@median, sub_T.Mean, g);
    my_mad = splitapply(@(x) mad(x,1), sub_T.Mean, g);
    for ichan = 1:length(chan_inc)
        nexttile
        hold on;
        idx = ch == chan_inc(ichan);
        amp_vec = amp(idx);
        cur_median = my_median(idx);
        cur_mad = my_mad(idx);
        cur_color = select_chan_color(ichan+1); 
        
        % Plot
        fill([amp_vec(:); flipud(amp_vec(:))], ...
            [cur_median(:)+cur_mad(:); flipud(cur_median(:)-cur_mad(:))], ...
            tableau_10('grey'),'FaceAlpha', 0.25, 'EdgeColor','none','HandleVisibility','off')
        plot(amp_vec,cur_median,'o-','LineWidth',2, ...
            'Color',cur_color,'MarkerFaceColor',cur_color,'MarkerEdgeColor',cur_color)
        title(chan_inc(ichan))
        xlabel('Amplitude (dB SPL)')
        ylabel('Lower CI Value')
    end
    sgtitle(sprintf('%d Hz',freq_inc(ifreq)))
end


% Model Fit Parameters Box plot

% Advanced heatmap version
%% HEATMAP
sub_T = rf_T(rf_T.CI == 99 ...
    & rf_T.Boot_It_N == 5000 ...
    & ismember(rf_T.Chan,chan_inc) ...
    & ismember(rf_T.Freq,freq_inc),:);
sub_T.Chan = removecats(sub_T.Chan);
freqs = unique(sub_T.Freq);
% sub_T.Val(sub_T.Val==260,:) = NaN;
all_the_amps = unique(sub_T.Amp);
allAmps = string(all_the_amps);

sub_T.Val(sub_T.Val==260,:) = NaN;
ampVals = unique(sub_T.Amp);
chans   = categories(sub_T.Chan);
G = groupsummary(sub_T,{'Freq','Chan','Amp'},{'median',@(x) mad(x,1)},'Val');
G.Properties.VariableNames(end-1:end) = {'med','madv'};
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
            text(cc,rr+0.22,sprintf('%.0f',D(i)),'HorizontalAlignment','center','FontSize',8,'Color',[.4 .4 .4]);
        end
    end
    title(sprintf('%d Hz N = %d',freqs(ifreq),length(unique(sub_2.Subj_ID))))
end

%% Threshold Box plot
% exclude_subj = [34];
% exclude_freq_for_subj = [55];
sub_T = thresh_T(ismember(thresh_T.Chan,chan_inc) ...
    & ismember(thresh_T.Freq,freq_inc),:); ...
    % & ~(ismember(thresh_T.Subj_ID,exclude_subj) & ismember(thresh_T.Freq,exclude_freq_for_subj)),:);
sub_T.Chan = removecats(sub_T.Chan);
N = groupsummary(sub_T,{'Freq','Chan'},'numunique','Subj_ID');
figure;
colororder([tableau_10('blue'); tableau_10('orange')])
boxchart(categorical(sub_T.Freq), sub_T.Threshold,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('Threshold (dB SPL)')
title('AEP Threshold Estimation')
legend

%% Reference code %%
% Line plot version
% figure;
% tiledlayout(3,1,'TileSpacing','tight','Padding','tight')
% for ifreq = 1:length(freqs)
%     cur_color = select_chan_color(ifreq);
%     sub_2 = sub_T(sub_T.Freq == freqs(ifreq),:);
%     [g,amps] = findgroups(sub_2.Amp);
%     m = splitapply(@median,sub_2.Val,g);
%     e = splitapply(@(v) mad(v,1), sub_2.Val, g);
%     nexttile;
%     p = errorbar(amps,m,e,'O-','Color',cur_color,'LineWidth',2,'MarkerFaceColor',cur_color);
%     xlim([min(all_the_amps) max(all_the_amps)])
%     xticks(all_the_amps)
%     xticklabels(all_the_amps)
%     title(sprintf('%d Hz N = %d',freqs(ifreq), length(unique(sub_2.Subj_ID))))
%     ylabel('N Trials Needed to detect')
%     xlabel('Stimulus Amplitude (dB)')
% end
% 
% % Heatmap version
% sub_T.Val(sub_T.Val==260,:) = NaN;
% figure;
% tiledlayout(3,1,'TileSpacing','tight','Padding','tight')
% for ifreq = 1:length(freqs)
%     sub_2 = sub_T(sub_T.Freq == freqs(ifreq),:);
%     nexttile;
%     h = heatmap(sub_2,'Amp','Chan', 'ColorVariable','Val', 'ColorMethod', 'median');
%     h.CellLabelFormat = '%.0f';
%     h.MissingDataColor = tableau_10('grey');
%     h.ColorbarVisible = 'off';
%     h.Colormap = interp1([0 1], [1 1 1; tableau_10('blue')], linspace(0,1,256));
%     h.XDisplayData = allAmps;
%     title(sprintf('%d Hz',freqs(ifreq)))
% end

%gscatter() scatterhistogram()