%% summary_polar_plot
% Plot phase component
for ichan = 1:numel(chan_inc)
    cur_chan = chan_inc(ichan);
    for ifreq = 1:numel(freq_inc)
        cur_freq = freq_inc(ifreq);
        amp_vec = unique(T_polar.Amp(T_polar.Freq == cur_freq));
        figure; tiledlayout(3,ceil(length(amp_vec)/3),"TileSpacing",'tight','Padding','tight')
        % Calculate maximum range for plotting
        rmax = max(T_polar.Mag_ON(T_polar.Freq == cur_freq & ...
            ismember(T_polar.Chan,cur_chan),:));
        for iamp = 1:numel(amp_vec)
            nexttile
            cur_amp = amp_vec(iamp);
            sub_T = T_polar(T_polar.Amp == cur_amp & ...
                T_polar.Freq == cur_freq & ...
                ismember(T_polar.Chan, cur_chan),:);
            % Normalize by maximum
            max_mag = groupsummary(sub_T,{'Subj_ID','Freq','Amp','Chan'},'max','Mag_ON');
            polarscatter(sub_T.Angle_ON, sub_T.Mag_ON, 50, tableau_10('blue'),"filled","MarkerFaceAlpha", 0.7);
            hold on;
            polarscatter(sub_T.Angle_OFF, sub_T.Mag_OFF, 50,tableau_10('orange'),"filled","MarkerFaceAlpha", 0.7);
            title(string(amp_vec(iamp)))
            if iamp ~= 1
                thetaticklabels([]);
            end
            ax = gca; ax.RAxis.FontSize = 7;
        end
        sgtitle(sprintf('Channel: %s | Frequency: %d Hz', cur_chan, cur_freq));
    end
end