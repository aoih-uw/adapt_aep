%% summary_plot_growth_function
% Uses T_F which has the raw F growth function values
% F
figure;
tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
for ifreq = 1:length(freq_inc)
    nexttile
    cur_PAL_cor = PAL_cor(ifreq);
    sub_T = T_F(ismember(T_F.Chan,chan_inc)  ...
        & T_F.Freq == freq_inc(ifreq),:);
    % All data
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 1,log_trans_alpha, 'log_{10}(F)', 'All',1,cur_PAL_cor);
end
legend(string(chan_inc),'Box','off')
linkaxes(findobj(gcf, 'Type', 'axes', 'XAxisLocation', 'bottom'), 'y')
% Simulated lower asymptote data
figure;
tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
for ifreq = 1:length(freq_inc)
    nexttile
    sub_T = T_F(ismember(T_F.Chan,chan_inc)  ...
        & T_F.Freq == freq_inc(ifreq),:);
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 1,log_trans_alpha, 'log_{10}(F)', 'Sim',1,[]);
end
legend(string(chan_inc),'Box','off')
linkaxes

% 2f
figure;
tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
for ifreq = 1:length(freq_inc)
    nexttile
    sub_T = T_twof(ismember(T_twof.Chan,chan_inc)  ...
        & T_twof.Freq == freq_inc(ifreq),:);
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 0, [],'2f Magnitude (\muV)','Mean',0,[]);
end
legend(string(chan_inc),'Box','off')
linkaxes

function plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, plot_y_cross,log_trans_alpha, my_ylabel, val_name, is_F, cur_PAL_cor)
cur_colors = [tableau_10('teal'); tableau_10('yellow')];
% Create a common grid of amplitudes
vals = sub_T.(val_name);
if is_F
    vals = log10(max(vals,realmin,'includenan'));
end
% Find every unique combination of subjid, chan, amp, and freq
[g, ch,amp] = findgroups(sub_T.Chan,sub_T.Amp);
my_n = splitapply(@(x) sum(~isnan(x)), vals, g);
% g same height as sub_T, showing which full model fit curve that row belongs to
% sid/ch/fr all nGroups long, sid(7), ch(7), fr(7) tell you what group 7 is

my_median = splitapply(@(x) median(x,'omitnan'), vals, g);
my_mad = splitapply(@(x) mad(x,1), vals, g);

% Plot both figures on same axes
hold on;
for ichan = 1:length(chan_inc)
    idx = ch == chan_inc(ichan);
    cur_color = cur_colors(ichan,:);

    x_vec = amp(idx);
    x_vec_mod = linspace(min(x_vec), max(x_vec),500);
    y_vec = my_median(idx);

    % fit model
    [p, logistic, ~] = param_logistic...
            (y_vec, x_vec);
        y_vec_mod = logistic(p,x_vec_mod);

    fill([x_vec; flipud(x_vec)], ...
        [y_vec+my_mad(idx); flipud(y_vec-my_mad(idx))], ...
        cur_color,'FaceAlpha',0.25,'EdgeColor','none','HandleVisibility','off')
    plot(x_vec,y_vec,'o','LineWidth',2, ...
        'Color',cur_color,'MarkerFaceColor',cur_color,'MarkerEdgeColor',cur_color,'HandleVisibility','off')
    hold on;
    plot(x_vec_mod,y_vec_mod,'Color',cur_color,'LineWidth',2)

    if plot_y_cross
    cross_idx = find(y_vec > log_trans_alpha, 1,'first');
    if ~isempty(cross_idx)
        xline(x_vec(cross_idx), '--', sprintf('%.1f', x_vec(cross_idx)), ...
            'Color', cur_color, 'LabelVerticalAlignment', 'bottom', ...
            'LabelHorizontalAlignment', 'center','LabelOrientation','horizontal', 'FontSize', 13,'HandleVisibility','off');
    end
    yline(log_trans_alpha,'--','Color',tableau_10('grey'),'HandleVisibility','off')
    end

    xlim([80 143])
end
xlabel('Amplitude (dB re: 1\muPa)')
ylabel(my_ylabel)
ax1 = gca;

% Second x axes, placed in the same tile
if ~isempty(cur_PAL_cor)
    ax2 = axes(ax1.Parent, 'XAxisLocation', 'top', 'Color', 'none', ...
        'XLim', ax1.XLim - cur_PAL_cor);
    ax2.YAxis.Visible = 'off';
    ax2.Layout.Tile = ax1.Layout.Tile;
    ax2.Layout.Tile = ax1.Layout.Tile;
    xlabel(ax2, 'dB re: 1 m/s^2')
    title(ax2, sprintf('%d Hz', freq_inc(ifreq)))
    axes(ax1)
else
    title(ax1, sprintf('%d Hz', freq_inc(ifreq)))
end
end