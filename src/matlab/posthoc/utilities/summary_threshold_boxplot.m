%% summary_threshold_boxplot
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
n = splitapply(@(x) sum(~isnan(x)), sub_T.Model_Thresh, g); % count non-NaN entries in each group

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