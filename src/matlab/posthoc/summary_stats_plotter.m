% Categories are metadata they dont get removed when you filter the data
rf_T.Chan = mergecats(rf_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
thresh_T.Chan = mergecats(thresh_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
chan_inc = ["Subcutaneous", "Subcranial"];
freq_inc = [55, 100, 410];

%% Model Fit Parameters Box plot
sub_p = mp_T(ismember(mp_T.Chan,chan_inc)  ...
        & ismember(mp_T.Freq, freq_inc),:);

figure; tiledlayout(1,4,'TileSpacing','tight','Padding','tight');
colororder([tableau_10('blue'); tableau_10('orange')])

% a
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.a, "GroupByColor",sub_p.Chan)
title('Upper arm slope (a)')
xlabel('Frequency')
ylabel('a')

% k
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.k, "GroupByColor",sub_p.Chan)
title('Bend sharpness (k)')
xlabel('Frequency')
ylabel('k')

% x0
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.x0, "GroupByColor",sub_p.Chan)
title('Bend location (x0)')
xlabel('Frequency')
ylabel('x0')
ylim([105 150])

% b
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.b, "GroupByColor",sub_p.Chan)
title('Noise floor (b)')
xlabel('Frequency')
ylabel('b')

legend({'Subcutaneous','Subcranial'}, 'Location','northwest', 'Box','off')

%% Low CI Fit plot
for ifreq = 1:length(freq_inc)
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    sub_T = lowCI_T(ismember(lowCI_T.Chan,chan_inc)  ...
        & lowCI_T.Freq == freq_inc(ifreq),:);
    % sub_T.Mean = low CI value of bootstrap distribution
    % sub_T.STD = num of trials needed to find response

    % Create a common grid of amplitudes
    % Find every unique combination of subjid, chan, amp, and freq
    [g, ch,amp] = findgroups(sub_T.Chan,sub_T.Amp);
    n = accumarray(g,1); % get count of number of data points 
    my_n = splitapply(@numel, sub_T.Mean, g);
    % g same height as sub_T, showing which full model fit curve that row belongs to
    % sid/ch/fr all nGroups long, sid(7), ch(7), fr(7) tell you what group 7 is

    my_median = splitapply(@median, sub_T.Mean, g);
    my_mad = splitapply(@(x) mad(x,1), sub_T.Mean, g);
    for ichan = 1:length(chan_inc)
        nexttile
        hold on;
        idx = ch == chan_inc(ichan);
        cur_n_count = n(idx);
        amp_vec = amp(idx);
        cur_median = my_median(idx);
        cur_mad = my_mad(idx);
        cur_color = select_chan_color(ichan+1);

        % Plot
        fill([amp_vec(:); flipud(amp_vec(:))], ...
            [cur_median(:)+cur_mad(:); flipud(cur_median(:)-cur_mad(:))], ...
            cur_color,'FaceAlpha', 0.15, 'EdgeColor','none','HandleVisibility','off')
        plot(amp_vec,cur_median,'o-','LineWidth',2, ...
            'Color',cur_color,'MarkerFaceColor',cur_color,'MarkerEdgeColor',cur_color)
        title(chan_inc(ichan))
        subtitle(sprintf('N = %d-%d', min(my_n(idx)), max(my_n(idx))))
        xlabel('Amplitude (dB SPL)')
        ylabel('Lower CI Value')
    end

    % Plot both figures on same axes
    nexttile
    hold on;
    for ichan = 1:length(chan_inc)
        idx = ch == chan_inc(ichan);
        cur_color = select_chan_color(ichan+1);
        fill([amp(idx); flipud(amp(idx))], ...
            [my_median(idx)+my_mad(idx); flipud(my_median(idx)-my_mad(idx))], ...
            cur_color,'FaceAlpha',0.25,'EdgeColor','none','HandleVisibility','off')
        plot(amp(idx),my_median(idx),'o-','LineWidth',2, ...
            'Color',cur_color,'MarkerFaceColor',cur_color,'MarkerEdgeColor',cur_color)
    end
    title('Both channels')
    xlabel('Amplitude (dB SPL)')
    ylabel('Lower CI Value')
    legend(string(chan_inc))

    sgtitle(sprintf('%d Hz',freq_inc(ifreq)))
end

%% HEATMAP
sub_T = rf_T(rf_T.CI == 99 ...
    & rf_T.Boot_It_N == 5000 ...
    & ismember(rf_T.Chan,chan_inc) ...
    & ismember(rf_T.Freq,freq_inc),:);
sub_T.Chan = removecats(sub_T.Chan);
[g, chan, freq, amp] = findgroups(sub_T.Chan, sub_T.Freq, sub_T.Amp);
n = accumarray(g,1);
freqs = unique(sub_T.Freq);
% sub_T.Val(sub_T.Val==260,:) = NaN;
all_the_amps = unique(sub_T.Amp);
allAmps = string(all_the_amps);

ampVals = unique(sub_T.Amp);
chans   = categories(sub_T.Chan);
G = groupsummary(sub_T,{'Freq','Chan','Amp'},{'median',@(x) mad(x,1)},'Val');
G.Properties.VariableNames(end-1:end) = {'med','madv'};
mask = G.med == 260;
G.med(mask) = NaN;
G.madv(mask) = NaN;
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
        if M(i) ~= 10
            text(cc,rr-0.15,sprintf('%.0f',M(i)),'HorizontalAlignment','center','FontSize',12);
        end
        if ~isnan(D(i))
            text(cc,rr+0.22,sprintf('%.0f',D(i)),'HorizontalAlignment','center','FontSize',8,'Color',[.4 .4 .4]);
        end
        if ~isnan(N(i))
    text(cc,rr+0.38,sprintf('%d',N(i)),'HorizontalAlignment','center','FontSize',6,'Color',[.4 .4 .4]);
        end

    end
    title(sprintf('%d Hz',freqs(ifreq)),'FontSize',14)
end

%% Threshold Box plot
% exclude_subj = [34];
% exclude_freq_for_subj = [55];
sub_T = thresh_T(ismember(thresh_T.Chan,chan_inc) ...
    & ismember(thresh_T.Freq,freq_inc),:); ...
    % & ~(ismember(thresh_T.Subj_ID,exclude_subj) & ismember(thresh_T.Freq,exclude_freq_for_subj)),:);
sub_T.Chan = removecats(sub_T.Chan);
figure;
colororder([tableau_10('blue'); tableau_10('orange')])
freqs = unique(sub_T.Freq);
[~,fx] = ismember(sub_T.Freq, freqs); % Turn frequencies into x positions
chans = categories(sub_T.Chan); 
w = 0.6;
boxchart(fx, sub_T.Threshold, 'GroupByColor', sub_T.Chan, 'BoxWidth', w) % Split groups by channel
hold on

% Add N count annotation
[g,gchan,gfreq] = findgroups(sub_T.Chan,sub_T.Freq); % Find unique combinations of chan and freq in the filtered table
n = splitapply(@numel,sub_T.Threshold,g); % count the number of entries of sub_T.Threshold within each of the # of unique groups signified by g

% Where did each box land?
[~,ci] = ismember(sub_T.Chan, chans);
gx = (((1:numel(chans))-0.5)/numel(chans) - 0.5)*w; % x placement of each group
X = fx + gx(ci)';

% Get the x location for the text
[~,gci] = ismember(gchan, chans); % identify the idx value of the gchan associated with the chans/box plots order
[~,gfx] = ismember(gfreq, freqs);
text(gfx + gx(gci)', repmat(89,size(n)), string(n), ...
    'HorizontalAlignment', 'center', 'FontSize', 9,'Color',tableau_10('grey'))

% connect paired subjects within each frequency
% Create a list of unique IDs for each frequency and subject ID value, 
% two values for each channels will be able to be selected for one unique frequency and subject ID
g = findgroups(fx, sub_T.Subj_ID); for j = 1:max(g)
    k = g == j; % loop by subject
    plot(X(k), sub_T.Threshold(k), '-', 'Color', tableau_10('grey'), ...
        'HandleVisibility', 'off')
end

for i = 1:numel(chans)
    k = ci == i;
    scatter(X(k), sub_T.Threshold(k), 30, 'filled', ...
        'MarkerFaceColor', select_chan_color(i+1), 'MarkerFaceAlpha', 0.2, ...
        'MarkerEdgeColor', select_chan_color(i+1), 'HandleVisibility', 'off')
end

xticks(1:numel(freqs)); xticklabels(string(freqs))
ylim([85 145])
xlabel('Frequency (Hz)'); ylabel('Threshold (dB SPL)')
title('AEP Threshold Estimation')
legend({'Subcutaneous','Subcranial'}, 'Location','northwest', 'Box','off')

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