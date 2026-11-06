%% summary_model_robustness
sub_T = T_error(ismember(T_error.Chan,chan_inc) & ...
    ismember(T_error.Freq,freq_inc), :);

method_types = unique(sub_T.Method);
method_types = method_types(1:2);
for ichan = 1:numel(chan_inc)
    tmp_T = sub_T(ismember(sub_T.Chan,chan_inc(ichan)),:);
    figure; 
    tiledlayout(numel(method_types),numel(freq_inc),'TileSpacing','tight','Padding','tight')
    for imethod = 1:numel(method_types)
        tmp_2_T = tmp_T(ismember(tmp_T.Method,method_types(imethod)),:);
        for ifreq = 1:numel(freq_inc)
            cur_color = select_chan_color(ifreq);
            tmp_3_T = tmp_2_T(ismember(tmp_2_T.Freq,freq_inc(ifreq)),:);
            G = groupsummary(tmp_3_T, 'Step', {@median, @(x) mad(x,1)},'Error');
            s = G.Step; m = G{:,3}; d = G{:,4};
            nexttile; hold on
            fill([0 20 20 0],[-5 -5 5 5],tableau_10('grey'),'FaceAlpha',0.1,'EdgeColor','none')
            fill([s; flipud(s)],[m-d; flipud(m+d)],cur_color,'FaceAlpha',0.3,'EdgeColor','none')
            plot(s,m,'-o','Color',cur_color,'MarkerFaceColor',cur_color)
            yline(0,'--')
            title(sprintf('%g Hz'),freq_inc(ifreq))
            ylim([-7 30])
            xlim([0 18])
            if ifreq == 1
                ylabel([string(method_types(imethod)); "Error (dB)"],'Interpreter','none')
            end
            xlabel('N data points removed')
        end
    end
    sgtitle(chan_inc(ichan))
end