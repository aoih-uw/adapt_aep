%% summary_threshold_comparisons
myColors = [tableau_10('red'); tableau_10('green');tableau_10('purple')];
myChanColors = [tableau_10('teal'); tableau_10('yellow')];

%% Compare F Stat Threshold vs. Model
figure; tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
for ichan = 1:length(chan_inc)
    nexttile
    cur_T = join_T(join_T.Chan == chan_inc(ichan),:);
    cur_color = select_chan_color(ichan + 1);
    scatter(cur_T,"Heat_Thresh",'Model_Thresh','filled','SizeData',30,'ColorVariable', 'Freq','LineWidth', 1.5,...
        'MarkerFaceColor',cur_color,'XJitter','rand','XJitterWidth',1)
    hold on;
    % Set color
    colormap(gca, myColors)

    % Display unity line
    x_vec = linspace(90,145,100);
    y_vec = x_vec;
    plot(x_vec,y_vec,'--','Color',tableau_10('grey'))

    % Show +/- 5 dB difference range
    xb = [x_vec, fliplr(x_vec)];
    yb = [x_vec + 5, fliplr(x_vec - 5)];
    fill(xb, yb, tableau_10('grey'), 'FaceAlpha', 0.1, 'EdgeColor', 'none')

    xlabel('F Stat Threshold')
    ylabel('Model Threshold')
    title(chan_inc(ichan))
end
sgtitle('Are F Stat threshold and model thresholds in good agreement?')

%% Join tables
size_T = outerjoin(join_T,T_wl,'Keys',{'Subj_ID'}, 'MergeKeys',true);

%% Compare Thresholds to body size
figure; tiledlayout(3,1,'TileSpacing','tight','Padding','tight')
% Weight
for ifreq = 1:numel(freq_inc)
    ax = nexttile;
    for ichan = 1:numel(chan_inc)
        cur_color = myChanColors(ichan,:);

        % Select current frequency and channel
        t_T = size_T(size_T.Freq == string(freq_inc(ifreq)) & ...
            size_T.Chan == chan_inc(ichan),:);

        % Calculate Fulton's Condition Factor K = W in grams /L in cm ^3
        t_T.Fultons_K = t_T.Weight./(t_T.Length).^3;
        scatter(t_T.Weight,t_T.Model_Thresh,[],cur_color,'filled','MarkerFaceAlpha',0.7)
        hold on;

        % Fit line
        xvar = 'Weight';
        mdl = fitlm(t_T, ['Model_Thresh ~ ' xvar]);
        b = mdl.Coefficients.Estimate;
        xl = [min(t_T.(xvar)) max(t_T.(xvar))];
        h(ichan) = plot(ax, xl, b(1) + b(2)*xl, 'Color', cur_color, 'LineWidth', 2, ...
            'DisplayName', sprintf('(%.2f, %.3g)', ...
            mdl.Rsquared.Ordinary, mdl.Coefficients.pValue(2)));

        % Label the line with the stats
        text(ax, xl(2), b(1) + b(2)*xl(2), sprintf('(%.2f, %.3g)', ...
            mdl.Rsquared.Ordinary, mdl.Coefficients.pValue(2)), ...
            'Color', cur_color, 'FontSize', 8, 'VerticalAlignment', 'middle')

    end
    title(ax, string(freq_inc(ifreq)))
    xlim(ax, [50 200])
    if ifreq == 2
        xlabel('Weight (g)')
    end

    if ifreq == 1
        ylabel('Threshold (dB SPL)')
    end

end
sgtitle('Fish size vs. Estimated Thresholds')


%% Compare all data threshold with simulated lower asymptote threshold
figure;tiledlayout(1,2,'TileSpacing','tight','Padding','tight')
my_min = 90;
my_max = 140;
for i = 1:numel(chan_inc)
    nexttile
    cur_chan = sub_T(sub_T.Chan == chan_inc{i},:);
    lims = [my_min my_max];
    fill([lims fliplr(lims)], [lims+5 fliplr(lims)-5], tableau_10('grey'), ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off')
    hold on;
    plot(lims,lims,'--','Color',tableau_10('grey'))
    gscatter(cur_chan.Model_Thresh, cur_chan.Sim, cur_chan.Freq,myColors,'.', 15)
    title(chan_inc{i}); xlabel('All'); ylabel('Sim'); axis equal
    xlabel('Threshold with All Data (dB)')
    ylabel('Threshold with Simulated Asymptote (dB)')

end
sgtitle('Are Simulated Asymptote Model in Good Agreement with the Full Dataset?')
