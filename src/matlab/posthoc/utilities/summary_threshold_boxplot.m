%% summary_threshold_boxplot
freqs = unique(sub_T.Freq);
[~,idx] = ismember(sub_T.Freq,freqs);
sub_T.PAL_thresh = sub_T.Model_Thresh - PAL_cor(idx)';
cur_colors = [tableau_10('teal'); tableau_10('yellow')];

figure;
colororder(cur_colors)
tiledlayout(1,2,"TileSpacing","tight",'Padding','tight');

% Plot SPL
nexttile
[~,fx] = ismember(sub_T.Freq, freqs); % Turn frequencies into x positions
chans = categories(sub_T.Chan);
w = 0.6;
boxchart(fx, sub_T.Model_Thresh, 'GroupByColor', sub_T.Chan, 'BoxWidth', w) % Split groups by channel
hold on

% Add N count annotation
[g,gchan,gfreq] = findgroups(sub_T.Chan,sub_T.Freq); % Find unique combinations of chan and freq in the filtered table
n = splitapply(@(x) sum(~isnan(x)), sub_T.Model_Thresh, g); % count non-NaN entries in each group
total_n_subj = splitapply(@(x) numel(unique(x)), sub_T.Subj_ID, g); % count non-NaN entries in each group
no_thresh = total_n_subj - n;
my_prc = compose('%1.0f%%', (1-(no_thresh./total_n_subj))*100);
% Where did each box land?
[~,ci] = ismember(sub_T.Chan, chans);
gx = (((1:numel(chans))-0.5)/numel(chans) - 0.5)*w; % x placement of each group
X = fx + gx(ci)';

% Get the x location for the text
[~,gci] = ismember(gchan, chans); % identify the idx value of the gchan associated with the chans/box plots order
[~,gfx] = ismember(gfreq, freqs);
text(gfx + gx(gci)', repmat(145,size(my_prc)), string(my_prc), ...
    'HorizontalAlignment', 'center', 'FontSize', 11,'Color',tableau_10('grey'))

% connect paired subjects within each frequency
% Create a list of unique IDs for each frequency and subject ID value,
% two values for each channels will be able to be selected for one unique frequency and subject ID
g = findgroups(fx, sub_T.Subj_ID); for j = 1:max(g)
    k = g == j; % loop by subject
    plot(X(k), sub_T.Model_Thresh(k), '-', 'Color', tableau_10('grey'), ...
        'HandleVisibility', 'off')
end

% Marker
% for i = 1:numel(chans)
%     k = ci == i;
%     scatter(X(k), sub_T.Model_Thresh(k), 30, 'filled', ...
%         'MarkerFaceColor', select_chan_color(i+1), 'MarkerFaceAlpha', 0.2, ...
%         'MarkerEdgeColor', select_chan_color(i+1), 'HandleVisibility', 'off')
% end

xticks(1:numel(freqs)); xticklabels(string(freqs))
ylim([85 150])
yticks(85:5:150)
xlabel('Frequency (Hz)'); ylabel('Threshold (dB SPL)')
title('Sound Pressure')

% Plot PAL
nexttile
[~,fx] = ismember(sub_T.Freq, freqs); % Turn frequencies into x positions
chans = categories(sub_T.Chan);
w = 0.6;
boxchart(fx, sub_T.PAL_thresh, 'GroupByColor', sub_T.Chan, 'BoxWidth', w) % Split groups by channel
hold on

% Add N count annotation
[g,gchan,gfreq] = findgroups(sub_T.Chan,sub_T.Freq); % Find unique combinations of chan and freq in the filtered table
n = splitapply(@(x) sum(~isnan(x)), sub_T.PAL_thresh, g); % count non-NaN entries in each group

% Where did each box land?
[~,ci] = ismember(sub_T.Chan, chans);
gx = (((1:numel(chans))-0.5)/numel(chans) - 0.5)*w; % x placement of each group
X = fx + gx(ci)';

% Get the x location for the text
[~,gci] = ismember(gchan, chans); % identify the idx value of the gchan associated with the chans/box plots order
[~,gfx] = ismember(gfreq, freqs);
text(gfx + gx(gci)', repmat(110,size(my_prc)), my_prc, ...
    'HorizontalAlignment', 'center', 'FontSize', 11,'Color',tableau_10('grey'))

% connect paired subjects within each frequency
% Create a list of unique IDs for each frequency and subject ID value,
% two values for each channels will be able to be selected for one unique frequency and subject ID
g = findgroups(fx, sub_T.Subj_ID); for j = 1:max(g)
    k = g == j; % loop by subject
    plot(X(k), sub_T.PAL_thresh(k), '-', 'Color', tableau_10('grey'), ...
        'HandleVisibility', 'off')
end

% Marker
% for i = 1:numel(chans)
%     k = ci == i;
%     scatter(X(k), sub_T.PAL_thresh(k), 30, 'filled', ...
%         'MarkerFaceColor', select_chan_color(i+1), 'MarkerFaceAlpha', 0.2, ...
%         'MarkerEdgeColor', select_chan_color(i+1), 'HandleVisibility', 'off')
% end

xticks(1:numel(freqs)); xticklabels(string(freqs))
xlabel('Frequency (Hz)'); ylabel('Threshold (dB m/s^2)')
title('Particle Acceleration')
legend({'Subcranial','Subcutaneous'}, 'Location','southeast', 'Box','off')
ylim([40 115])
yticks(40:5:115)