%% summary_plot_growth_function
% Low CI
for ifreq = 1:length(freq_inc)
    sub_T = T_lowCI(ismember(T_lowCI.Chan,chan_inc)  ...
        & T_lowCI.Freq == freq_inc(ifreq),:);

    % All data
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 1, 'Lower CI Value (\muV)', 'All');

    % Simulated lower asymptote data
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 1, 'Lower CI Value (\muV)', 'Sim');
end

% 2f
for ifreq = 1:length(freq_inc)
    sub_T = T_twof(ismember(T_twof.Chan,chan_inc)  ...
        & T_twof.Freq == freq_inc(ifreq),:);
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 0, '2f Magnitude (\muV)','Mean');
end

function plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, plot_y_cross, my_ylabel, val_name)
% Create a common grid of amplitudes
vals = sub_T.(val_name);
% Find every unique combination of subjid, chan, amp, and freq
[g, ch,amp] = findgroups(sub_T.Chan,sub_T.Amp);
n = accumarray(g,1); % get count of number of data points
my_n = splitapply(@numel, vals, g);
% g same height as sub_T, showing which full model fit curve that row belongs to
% sid/ch/fr all nGroups long, sid(7), ch(7), fr(7) tell you what group 7 is

my_median = splitapply(@median, vals, g);
my_mad = splitapply(@(x) mad(x,1), vals, g);
for ichan = 1:length(chan_inc)
    nexttile
    hold on;
    idx = ch == chan_inc(ichan);
    cur_n_count = n(idx);
    amp_vec = amp(idx);
    cur_median = my_median(idx);
    cur_mad = my_mad(idx);

    % Fit softplus
    [p, ~, ~, softplus, fq] ...
        = param_softplus(cur_median, [], amp_vec, [],0);

    x_vec = linspace(min(amp_vec), max(amp_vec),500);
    y_vec = softplus(p,x_vec);

    cur_color = select_chan_color(ichan+1);

    % Plot
    fill([amp_vec(:); flipud(amp_vec(:))], ...
        [cur_median(:)+cur_mad(:); flipud(cur_median(:)-cur_mad(:))], ...
        cur_color,'FaceAlpha', 0.15, 'EdgeColor','none','HandleVisibility','off')
    hold on

    % Model Fit line
    plot(x_vec,y_vec,'Color',cur_color,'LineWidth',2);

    % Raw data
    plot(amp_vec,cur_median,'o','LineWidth',2, ...
        'Color',cur_color,'MarkerFaceColor',cur_color,'MarkerEdgeColor',cur_color)
    hold on

    if plot_y_cross
        idx = find(y_vec > 0, 1,'first');
        if ~isempty(idx)
            xline(x_vec(idx), '--', sprintf('%.2f', x_vec(idx)), ...
                'Color', cur_color, 'LabelVerticalAlignment', 'middle', ...
                'LabelHorizontalAlignment', 'center','LabelOrientation','horizontal', 'FontSize', 13);
        end
    end

    yline(0,'--','Color',tableau_10('grey'))
    title(chan_inc(ichan))
    subtitle(sprintf('N = %d-%d', min(my_n), max(my_n)))
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

sgtitle(sprintf('%d Hz (%s)',freq_inc(ifreq), val_name))
end