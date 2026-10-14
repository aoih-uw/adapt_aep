%% summary_plot_2f_consistency

% Find first timestamp for each subject
T_earliest = groupsummary(T_twof_over_time,{'Subj_ID','Freq','Amp'},'min','Time');
% Join tables
cur_T = join(T_twof_over_time,T_earliest(:,{'Subj_ID','Freq','Amp','min_Time'}));
cur_T.rel_time = cur_T.Time - cur_T.min_Time;
% Find the AbsVal associated with the first timestamp
first_vals = cur_T(cur_T.rel_time == 0, {'Subj_ID','Freq','Amp','Chan','AbsVal'});
first_vals = renamevars(first_vals,'AbsVal','FirstVal');
first_vals = groupsummary(first_vals,{'Subj_ID','Freq','Amp','Chan'},'median','FirstVal');
cur_T = join(cur_T,first_vals(:,{'Subj_ID','Freq','Amp','Chan','median_FirstVal'}));
cur_T.rel_val = cur_T.AbsVal - cur_T.median_FirstVal;

% Plot absolute
for ichan = 1:length(chan_inc)
    cur_chan = chan_inc(ichan);
    figure;
    tiledlayout(3,9,'TileSpacing','tight','Padding','tight')
    for ifreq = 1:length(freq_inc)
        cur_color = my_colors{ifreq};
        cur_freq = freq_inc(ifreq);
        tmp_T = cur_T(cur_T.Freq == cur_freq & ...
            ismember(cur_T.Chan,cur_chan),:);

        amp_vec = [140:-3:116];
        for iamp = 1:length(amp_vec)
            nexttile
            cur_amp = amp_vec(iamp);
            % Take the median across same subject and same time point
            subj_T = groupsummary(tmp_T(tmp_T.Amp == cur_amp,:), {'Subj_ID', 'rel_time'},'median','AbsVal');
            subjs = unique(subj_T.Subj_ID);
            for isubj = 1:length(subjs)
                cur_subj = subjs(isubj);
                s_T = subj_T(subj_T.Subj_ID == cur_subj,:);
                h = plot(hours(s_T.rel_time), s_T.median_AbsVal, 'Color', [cur_color 0.6]);
                h.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Subject', repmat(cur_subj, height(s_T), 1));
                hold on;
            end
            % FORMATTING
            yline(0,'--')
            xlabel('Time (h)')
            title(sprintf('%d dB | %d Hz',cur_amp, cur_freq))
        end
    end
    sgtitle(string(cur_chan))
end

% Plot relative
for ichan = 1:length(chan_inc)
    cur_chan = chan_inc(ichan);
    figure;
    tiledlayout(3,9,'TileSpacing','tight','Padding','tight')
    for ifreq = 1:length(freq_inc)
        cur_color = my_colors{ifreq};
        cur_freq = freq_inc(ifreq);
        tmp_T = cur_T(cur_T.Freq == cur_freq & ...
            ismember(cur_T.Chan,cur_chan),:);
        
        % Set amp_vec based on freqs
        % if cur_freq == 55
        %     amp_vec = [140 110 83];
        % elseif cur_freq == 100
        %     amp_vec = [140 116 95];
        % elseif cur_freq == 410
        %     amp_vec = [140 128 116];
        % end

        amp_vec = [140:-3:116];
        for iamp = 1:length(amp_vec)
            nexttile
            cur_amp = amp_vec(iamp);
            subj_T = groupsummary(tmp_T(tmp_T.Amp == cur_amp,:), {'Subj_ID', 'rel_time'},'median','rel_val');
            subjs = unique(subj_T.Subj_ID);
            for isubj = 1:length(subjs)
                cur_subj = subjs(isubj);
                s_T = subj_T(subj_T.Subj_ID == cur_subj,:);
                h = plot(hours(s_T.rel_time), s_T.median_rel_val, 'Color', [cur_color 0.6]);
                h.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Subject', repmat(cur_subj, height(s_T), 1));
                hold on;
            end
            % FORMATTING
            yline(0,'--')
            xlabel('Time (h)')
            title(sprintf('%d dB | %d Hz',cur_amp, cur_freq))
        end
    end
    sgtitle(string(cur_chan))
end

% Slopes
figure;
tiledlayout(1,3,'TileSpacing','tight','Padding','tight')
for ifreq = 1:numel(freq_inc)
    nexttile
    tmp = T_slope(T_slope.Freq == freq_inc(ifreq),:);
    boxchart(tmp.Amp, tmp.Slope, 'GroupByColor',tmp.Chan)
    title(sprintf('%d Hz', freq_inc(ifreq)));
    xlabel('Stimulus Amplitude (dB SPL)')
    ylabel('Slope (\muV / Min)')
    yline(0,'--')
end
legend({'Subcranial','Subcutaneous'}, 'Location','northwest', 'Box','off')
sgtitle('Does 2f response stay stable across test?')