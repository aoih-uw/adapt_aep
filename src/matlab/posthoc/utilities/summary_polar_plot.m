%% summary_polar_plot
% Identify
% Normalize by maximum across all amplitudes across each subject
G = findgroups(T_polar.Subj_ID,T_polar.Freq,T_polar.Chan);
my_max = splitapply(@max,T_polar.Mag_ON,G);
T_polar.Max_Mag_ON = my_max(G);
T_polar.norm_Mag_ON = T_polar.Mag_ON./T_polar.Max_Mag_ON;

% Plot phase component
for ichan = 1:numel(chan_inc)
    cur_chan = chan_inc(ichan);
    for ifreq = 1:numel(freq_inc)
        cur_freq = freq_inc(ifreq);
        cur_color = select_chan_color(ifreq);
        amp_vec = unique(T_polar.Amp(T_polar.Freq == cur_freq));
        figure; tiledlayout(3,ceil(length(amp_vec)/3),"TileSpacing",'tight','Padding','tight')
        for iamp = 1:numel(amp_vec)
            nexttile
            cur_amp = amp_vec(iamp);
            sub_T = T_polar(T_polar.Amp == cur_amp & ...
                T_polar.Freq == cur_freq & ...
                ismember(T_polar.Chan, cur_chan),:);
            polarscatter(sub_T.Angle_ON, sub_T.norm_Mag_ON, 50, cur_color,"filled","MarkerFaceAlpha", 0.7);
            hold on;
            rlim([0 1]); title(string(amp_vec(iamp)))
            if iamp ~= 1
                thetaticklabels([]); rticklabels([]);
            end
            ax = gca; ax.RAxis.FontSize = 7;
        end
        sgtitle(sprintf('Channel: %s | Frequency: %d Hz', cur_chan, cur_freq));
    end
end

%% Per subject 
% Plot phase component
% Color idx
for ichan = 1:numel(chan_inc)
    cur_chan = chan_inc(ichan);
    for ifreq = 1:numel(freq_inc)
        cur_freq = freq_inc(ifreq);
        cur_color = select_chan_color(ifreq);
        amp_vec = unique(T_polar.Amp(T_polar.Freq == cur_freq));
        figure;
        sub_T = T_polar(T_polar.Freq == cur_freq & ...
            ismember(T_polar.Chan, cur_chan),:);
        subj_list = unique(sub_T.Subj_ID);
        tiledlayout(4,6,'TileSpacing','tight','Padding','tight')
        for isubj = 1:length(subj_list)
            nexttile
            tmp_T = sortrows(sub_T(sub_T.Subj_ID == subj_list(isubj),:),'Amp');
            polarscatter(tmp_T.Angle_ON, tmp_T.norm_Mag_ON, 50, cur_color,"filled","MarkerFaceAlpha",0.4);
            hold on;
            polarplot(tmp_T.Angle_ON, tmp_T.norm_Mag_ON, '-','Color',cur_color, 'LineWidth', 1);
            title(sprintf('%s | %.2f μV', string(subj_list(isubj)), tmp_T.Max_Mag_ON(1)))
            rlim([0 1]);
            if isubj ~= 1
                thetaticklabels([]); rticklabels([]);
            end
            ax = gca; ax.RAxis.FontSize = 7;
        end
        sgtitle(sprintf('Channel: %s | Frequency: %d Hz', cur_chan, cur_freq));
    end
end

%% Growth function of PLV ON and OFF
for ichan = 1:numel(chan_inc)
    figure; tiledlayout(1,length(freq_inc));
    for ifreq = 1:numel(freq_inc)
        nexttile
        hold on;
        cur_color = select_chan_color(ifreq);
        cur_T = T_polar(T_polar.Chan == chan_inc(ichan) & ...
            T_polar.Freq == freq_inc(ifreq),:);
        subj_list = unique(cur_T.Subj_ID);
        for isubj = 1:length(subj_list)
            tmp_T = cur_T(cur_T.Subj_ID == subj_list(isubj),:);
            plot(tmp_T.Amp,tmp_T.PLV_ON,'Color',cur_color,'LineWidth',.5);
            plot(tmp_T.Amp,tmp_T.PLV_OFF,'Color',tableau_10('grey'),'LineWidth',.5);
        end
        xlabel('Amplitude (dB)');
        ylabel('Phase Locking Value');
        title(sprintf('%d Hz',freq_inc(ifreq)))
        ylim([0 1])
        xlim([83 140])
    end
    sgtitle(sprintf('%s Phase Locking Value',chan_inc(ichan)));
end

%#% Check code
%% Median PLV across subjects
cond = ["ON","OFF"]; styles = ["-","--"];
figure; tiledlayout(1,numel(freq_inc));
for ifreq = 1:numel(freq_inc)
    nexttile; hold on;
    for ichan = 1:numel(chan_inc)
        if chan_inc(ichan) == "Subcranial"
            cur_color = tableau_10('blue');
        else
            cur_color = tableau_10('orange');
        end
        cur_T = T_polar(T_polar.Chan == chan_inc(ichan) & ...
            T_polar.Freq == freq_inc(ifreq),:);
        med_T = groupsummary(cur_T,'Amp',{'median',@(x) mad(x,1)},{'PLV_ON','PLV_OFF'});
        x = med_T.Amp;
        for ic = 1:numel(cond)
            m = med_T.("median_PLV_" + cond(ic));
            d = med_T.("fun1_PLV_" + cond(ic));
            fill([x; flipud(x)], [m+d; flipud(m-d)], cur_color, ...
                'FaceAlpha',0.2,'EdgeColor','none','HandleVisibility','off');
            plot(x, m, 'Color', cur_color, 'LineStyle', styles(ic), 'LineWidth', 1.5, ...
                'DisplayName', string(chan_inc(ichan)) + " " + cond(ic));
        end
    end
    xlabel('Amplitude (dB)');
    ylabel('Median Phase Locking Value');
    title(sprintf('%d Hz',freq_inc(ifreq)))
    ylim([0 1]); xlim([83 140])
end
legend('Location','best');
sgtitle('Median Phase Locking Value');