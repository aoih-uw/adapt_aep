%% summary_plot_growth_function
% Uses T_F which has the raw F growth function values
% Low CI
for ifreq = 1:length(freq_inc)
    sub_T = T_F(ismember(T_F.Chan,chan_inc)  ...
        & T_F.Freq == freq_inc(ifreq),:);

    % All data
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 1,log_trans_alpha, 'log_{10} F Stat (\muV)', 'All',1);

    % Simulated lower asymptote data
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 1,log_trans_alpha, 'log_{10} F Stat (\muV)', 'Sim',1);
end

% 2f
for ifreq = 1:length(freq_inc)
    sub_T = T_twof(ismember(T_twof.Chan,chan_inc)  ...
        & T_twof.Freq == freq_inc(ifreq),:);
    figure;
    tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
    plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, 0, [],'2f Magnitude (\muV)','Mean',0);
end

function plot_growth_func(sub_T,chan_inc,freq_inc,ifreq, plot_y_cross,log_trans_alpha, my_ylabel, val_name, is_F)
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
for ichan = 1:length(chan_inc)
    nexttile
    hold on;
    idx = ch == chan_inc(ichan);
    amp_vec = amp(idx);
    cur_median = my_median(idx);
    cur_mad = my_mad(idx);

    x_vec = linspace(min(amp_vec), max(amp_vec),500);
    if is_F
        % Fit logistic
        [p, logistic, ~] = param_logistic...
            (cur_median', reshape(amp_vec,1,[]));
        y_vec = logistic(p,x_vec);

    else
        % Fit softplus
        [p, ~, ~, softplus, ~] ...
            = param_softplus(cur_median, [], amp_vec, [],0);
        y_vec = softplus(p,x_vec);
    end

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
        cross_idx = find(y_vec > log_trans_alpha, 1,'first');
        if ~isempty(cross_idx)
            xline(x_vec(cross_idx), '--', sprintf('%.2f', x_vec(cross_idx)), ...
                'Color', cur_color, 'LabelVerticalAlignment', 'middle', ...
                'LabelHorizontalAlignment', 'center','LabelOrientation','horizontal', 'FontSize', 13);
        end
        yline(log_trans_alpha,'--','Color',tableau_10('grey'))
    end

    title(string(chan_inc(ichan)))
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

if plot_y_cross
    yline(log_trans_alpha,'--','Color',tableau_10('grey'))
else
    yline(0,'--','Color',tableau_10('grey'))
end

title('Both channels')
xlabel('Amplitude (dB SPL)')
ylabel(my_ylabel)
legend(string(chan_inc))

sgtitle(sprintf('%d Hz (%s)',freq_inc(ifreq), val_name))
end