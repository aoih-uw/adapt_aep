% Categories are metadata they dont get removed when you filter the data
outdir = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
rf_T.Chan = mergecats(rf_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
thresh_T.Chan = mergecats(thresh_T.Chan, ["subcutaneous","Subcutaneous"], "Subcutaneous");
chan_inc = ["Subcutaneous", "Subcranial"];
freq_inc = [55, 100, 410];

%% Low CI Fit Quality summary
% Filter dataset
sub_T = lowCI_fp_T(ismember(lowCI_fp_T.Freq, freq_inc) & ...
    ismember(lowCI_fp_T.Chan, chan_inc),:);

% Set up figure
tiledlayout(2,3,'TileSpacing','tight','Padding','tight')
colororder([tableau_10('blue'); tableau_10('orange')])

% Resnorm
nexttile
boxchart(categorical(sub_T.Freq), sub_T.Resnorm,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('SSE (\muV)')
title('Total Squared Errors of Fit')

% Number of pins
nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_a,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('a')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_k,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('k')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_x0,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('x0')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_b,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('b')
legend({'Subcutaneous','Subcranial'}, 'Location','northwest', 'Box','off')
sgtitle('Low CI Model Fit Quality')

%% Growth Function
% Low CI (Based on stable response idx)
for ifreq = 1:length(freq_inc)
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    sub_T = lowCI_T(ismember(lowCI_T.Chan,chan_inc)  ...
        & lowCI_T.Freq == freq_inc(ifreq),:);
    % sub_T.Mean = low CI value of bootstrap distribution
    % sub_T.STD = num of trials needed to find response

    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 1, 'Lower CI Value (\muV)');
end

% 2f (Based on first hit response idx)
for ifreq = 1:length(freq_inc)
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    sub_T = twof_T(ismember(twof_T.Chan,chan_inc)  ...
        & twof_T.Freq == freq_inc(ifreq),:);
    % sub_T.Mean = low CI value of bootstrap distribution
    % sub_T.STD = num of trials needed to find response

    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 0, '2f Magnitude (\muV)');
end

%% Hydrophone Acoustics Summary
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight');
sub_n = hydro_noise(ismember(hydro_noise.Freq,freq_inc),:);
sub_o = hydro_ON(ismember(hydro_noise.Freq,freq_inc),:);
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

%% HEATMAP
% Filter dataset
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

% First hit
G = groupsummary(sub_T,{'Freq','Chan','Amp'},{'median',@(x) mad(x,1)},'First');
make_heatmap(G,freqs,sub_T,chans,ampVals, 'First Hit')

% Last stable hit
G = groupsummary(sub_T,{'Freq','Chan','Amp'},{'median',@(x) mad(x,1)},'Stable');
make_heatmap(G,freqs,sub_T,chans,ampVals, 'First Stable Hit')

%% Compare Model vs. Bootstrap Threshold
% Find heatmap based threshold
T2 = sub_T(sub_T.First < 260,:);
% You need to filter by rows that are below 260 first since split apply needs a value per group, it cannot be empty
% Find groups finds the locations of unique combinations of the variables
% you input (Find every unique combo of subject and Frequency and Chan) so
% then you can analyze the result value of interest based on each unique
% group type
[g, Subj, Freq, Chan] = findgroups(T2.Subj_ID,T2.Freq, T2.Chan); % Identify what unique groups you want to identify by
Thresh = splitapply(@(a,f) min(a), T2.Amp, T2.First, g);
T3 = table(Subj,Freq,Chan,Thresh,'VariableNames',{'Subj_ID', 'Freq', 'Chan', 'Heat_Thresh'});

% Find model based threshold
% exclude_subj = [34];
% exclude_freq_for_subj = [55];
sub_T = thresh_T(ismember(thresh_T.Chan,chan_inc) ...
    & ismember(thresh_T.Freq,freq_inc),:); ...
    % & ~(ismember(thresh_T.Subj_ID,exclude_subj) & ismember(thresh_T.Freq,exclude_freq_for_subj)),:);
sub_T.Chan = removecats(sub_T.Chan);
sub_T.Properties.VariableNames{4} = 'Model_Thresh';

% Join tables
% Inner join = only includes rows of data only where there is overlap between the two Tables,
% there is a present threshold value in their respective tables
% Outer join = includes rows where both OR only one table had a value in the
% threshold value
join_T = outerjoin(T3,sub_T,'Keys',{'Subj_ID','Freq','Chan'}, 'MergeKeys',true);
join_T.Freq = categorical(join_T.Freq);
figure; tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
for ichan = 1:length(chan_inc)
    nexttile
    cur_T = join_T(join_T.Chan == chan_inc(ichan),:);
    cur_color = select_chan_color(ichan + 1);
    scatter(cur_T,"Heat_Thresh",'Model_Thresh','SizeData',60,'ColorVariable', 'Freq','LineWidth', 1.5)
    hold on;
    % Set color
    myColors = [tableau_10('red');tableau_10('blue'); tableau_10('orange')];
    colormap(gca, myColors)

    % Display unity line
    x_vec = linspace(90,145,100);
    y_vec = x_vec;
    plot(x_vec,y_vec,'--','Color',tableau_10('grey'))

    % Show +/- 5 dB difference range
    xb = [x_vec, fliplr(x_vec)];
    yb = [x_vec + 3, fliplr(x_vec - 3)];
    fill(xb, yb, tableau_10('grey'), 'FaceAlpha', 0.1, 'EdgeColor', 'none')

    xlabel('Bootstrap Threshold')
    ylabel('Model Threshold')
    title(chan_inc(ichan))
end
sgtitle('Threshold Estimation Method Comparison')

%% Compare Thresholds to body size
size_T = outerjoin(join_T,wl_T,'Keys',{'Subj_ID'}, 'MergeKeys',true);
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
myColors = [tableau_10('red');tableau_10('blue'); tableau_10('orange')];
cur_T = size_T(size_T.Chan == chan_inc(2),:);

% Plot Basic Length vs. Weight Correlation
nexttile
c = tableau_10('blue');
scatter(cur_T,"Weight","Length",'filled','SizeData',60, ...
    'MarkerFaceColor',c,'MarkerEdgeColor',c,'LineWidth',1.5)
p = polyfit(cur_T.Weight, cur_T.Length, 1);
text(0.05, 0.95, sprintf('slope = %.3f', p(1)), ...
    'Units','normalized', 'VerticalAlignment','top', 'Color', c)
hold on
xl = xlim;
% Significance
mdl = fitlm(cur_T,"Length ~ Weight");
pval = mdl.Coefficients.pValue("Weight");
plot(xl, polyval(p, xl),'Color', tableau_10('blue'), 'LineWidth', 2)
text(0.05, 0.95, sprintf('slope = %.3f, p = %.3g', ...
    mdl.Coefficients.Estimate("Weight"), pval), ...
    'Units','normalized', 'VerticalAlignment','top', 'Color', c)
title('Subject Weight vs. Length')

% Weight
ax = nexttile;
scatter(cur_T,"Weight",'Model_Thresh','filled','SizeData',60,'ColorVariable', 'Freq','LineWidth', 1.5)
colormap(gca, myColors)
xlabel('Weight (g)')
ylabel('Model Threshold')
title('Weight vs. Threshold')

% Length
nexttile
scatter(cur_T,"Length",'Model_Thresh','filled','SizeData',60,'ColorVariable', 'Freq','LineWidth', 1.5)
colormap(gca, myColors)
xlabel('Length (cm)')
ylabel('Model Threshold')
title('Length vs. Threshold')
sgtitle('Size and Auditory Threshold Comparison (Subcranial)')

%% Threshold Box plot
figure;
colororder([tableau_10('blue'); tableau_10('orange')])
freqs = unique(sub_T.Freq);
[~,fx] = ismember(sub_T.Freq, freqs); % Turn frequencies into x positions
chans = categories(sub_T.Chan);
w = 0.6;
boxchart(fx, sub_T.Model_Thresh, 'GroupByColor', sub_T.Chan, 'BoxWidth', w) % Split groups by channel
hold on

% Add N count annotation
[g,gchan,gfreq] = findgroups(sub_T.Chan,sub_T.Freq); % Find unique combinations of chan and freq in the filtered table
n = splitapply(@numel,sub_T.Model_Thresh,g); % count the number of entries of sub_T.Threshold within each of the # of unique groups signified by g

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
    plot(X(k), sub_T.Model_Thresh(k), '-', 'Color', tableau_10('grey'), ...
        'HandleVisibility', 'off')
end

for i = 1:numel(chans)
    k = ci == i;
    scatter(X(k), sub_T.Model_Thresh(k), 30, 'filled', ...
        'MarkerFaceColor', select_chan_color(i+1), 'MarkerFaceAlpha', 0.2, ...
        'MarkerEdgeColor', select_chan_color(i+1), 'HandleVisibility', 'off')
end

xticks(1:numel(freqs)); xticklabels(string(freqs))
ylim([85 145])
xlabel('Frequency (Hz)'); ylabel('Threshold (dB SPL)')
title('AEP Threshold Estimation')
legend({'Subcutaneous','Subcranial'}, 'Location','northwest', 'Box','off')

%% LOCAL FUNCTIONS %%
function make_heatmap(G,freqs,sub_T,chans,ampVals,mytitle)
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
sgtitle(mytitle)
end

function plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, plot_y_cross, my_ylabel)
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

    if plot_y_cross
        idx = find(cur_median > 0, 1,'first');
        xline(amp_vec(idx), '--', sprintf('%.2f', amp_vec(idx)), ...
            'Color', cur_color, 'LabelVerticalAlignment', 'middle', ...
            'LabelHorizontalAlignment', 'center','LabelOrientation','horizontal', 'FontSize', 13);
    end

    yline(0,'--','Color',tableau_10('grey'))
    title(chan_inc(ichan))
    subtitle(sprintf('N = %d-%d', min(my_n(idx)), max(my_n(idx))))
    xlabel('Amplitude (dB SPL)')
    ylabel(my_ylabel)
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
yline(0,'--','Color',tableau_10('grey'))

title('Both channels')
xlabel('Amplitude (dB SPL)')
ylabel('Lower CI Value')
legend(string(chan_inc))

sgtitle(sprintf('%d Hz',freq_inc(ifreq)))
end

% Apply Tufte
apply_tufte

% Save figs to powerpoint
save_figs_to_ppt(outdir, 'Midshipman AEP Summary Stats 2026')