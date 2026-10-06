%% summary_threshold_comparisons

%% Compare Bootstrap Threshold vs. Model
figure; tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
for ichan = 1:length(chan_inc)
    nexttile
    cur_T = join_T(join_T.Chan == chan_inc(ichan),:);
    cur_color = select_chan_color(ichan + 1);
    scatter(cur_T,"Heat_Thresh",'Model_Thresh','SizeData',60,'ColorVariable', 'Freq','LineWidth', 1.5)
    hold on;
    % Set color
    myColors = [tableau_10('blue'); tableau_10('orange');tableau_10('red')];
    colormap(gca, myColors)

    % Display unity line
    x_vec = linspace(90,145,100);
    y_vec = x_vec;
    plot(x_vec,y_vec,'--','Color',tableau_10('grey'))

    % Show +/- 3 dB difference range
    xb = [x_vec, fliplr(x_vec)];
    yb = [x_vec + 3, fliplr(x_vec - 3)];
    fill(xb, yb, tableau_10('grey'), 'FaceAlpha', 0.1, 'EdgeColor', 'none')

    xlabel('Bootstrap Threshold')
    ylabel('Model Threshold')
    title(chan_inc(ichan))
end
sgtitle('Are bootstrap threshold and model thresholds in good agreement?')

%% Compare Thresholds to body size
size_T = outerjoin(join_T,T_wl,'Keys',{'Subj_ID'}, 'MergeKeys',true);
figure; tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
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

%% Compare all data threshold with simulated lower asymptote threshold
figure;tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
my_min = 90;
my_max = 140;
for i = 1:numel(chans)
    nexttile
    cur_chan = sub_T(sub_T.Chan == chans{i},:);
    lims = [my_min my_max];
    fill([lims fliplr(lims)], [lims+3 fliplr(lims)-3], tableau_10('grey'), ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    hold on;
    plot(lims,lims,'--','Color',tableau_10('grey'))
    gscatter(cur_chan.Model_Thresh, cur_chan.Sim, cur_chan.Freq,myColors)
    title(chans{i}); xlabel('All'); ylabel('Sim'); axis equal
    xlabel('Threshold with All Data (dB)')
    ylabel('Threshold with Simulated Asymptote (dB)')

end
sgtitle('Are Simulated Asymptote Model in Good Agreement with the Full Dataset?')