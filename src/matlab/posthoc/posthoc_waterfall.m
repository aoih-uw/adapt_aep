% Function posthoc_waterfall
amp_vec = 95:3:140;
stim_type_vec = {'ONOFF'};
my_chans = [2,3,4];
target_freq_range = 3;
isubj = 1;
channel_names = {'2mm','4 mm', 'Subcutaneous'};
stim_freq = 100;
data_titles = {'Stim ON','Stim OFF','Stim ON-OFF'};

for itype = 1:length(stim_type_vec)
    if strcmp(stim_type_vec{itype},'trim')
        trials_in_avg = 1024;
    else
        trials_in_avg = 128;
    end

    for ichan = 1:length(my_chans)
        cur_chan = my_chans(ichan);
        if ichan == 1
            cur_color = tableau_10('blue');
        elseif ichan == 2
            cur_color = tableau_10('orange');
        else
            cur_color = tableau_10('purple');
        end

        figure;
        tiledlayout(1,3,"TileSpacing","tight","Padding","tight")
        cumu_offset = zeros(1,3);

        for iamp = 1:length(amp_vec)
            cur_freq_vec = squeeze(freq_vec(:,:,iamp, itype, ichan));
            cur_fft_vals_ON  = squeeze(ON_fft_vals(:,:,iamp, itype, ichan));
            cur_fft_vals_OFF = squeeze(OFF_fft_vals(:,:,iamp, 1, ichan));
            cur_phase_vec = squeeze(phase_vec(:,:,iamp,itype,ichan));

            nan_rows = any(isnan(cur_freq_vec),2) | any(isnan(cur_fft_vals_ON),2);
            cur_freq_vec(nan_rows,:) = [];
            cur_fft_vals_ON(nan_rows,:) = [];
            cur_fft_vals_OFF(nan_rows,:) = [];
            cur_phase_vec(nan_rows,:) = [];

            phase_types = unique(cur_phase_vec);
            n_per_phase = trials_in_avg / length(phase_types);
            rand_select = [];
            for iphase = 1:length(phase_types)
                cur_phase_idx = find(cur_phase_vec == phase_types(iphase));
                my_rand_phase_idx = randperm(length(cur_phase_idx), n_per_phase);
                rand_select = [rand_select ; cur_phase_idx(my_rand_phase_idx)];
            end

            select_trials_ON = cur_fft_vals_ON(rand_select,:);
            select_trials_OFF = cur_fft_vals_OFF(rand_select,:);
            diff_vec = select_trials_ON - select_trials_OFF;

            cur_mean = cat(1, mean(select_trials_ON,1), mean(select_trials_OFF,1), mean(diff_vec,1));

            for idata = 1:3
                nexttile(idata); hold on;
                plot(cur_freq_vec(1,:), cur_mean(idata,:)+cumu_offset(idata), 'LineWidth',2, 'Color',cur_color)
                text(105, cur_mean(idata,1)+cumu_offset(idata), num2str(amp_vec(iamp)), 'Color',cur_color)
                cumu_offset(idata) = cumu_offset(idata) + max(cur_mean(idata,:));
                xlim([0 1000])
            end
        end

        for idata = 1:3
            nexttile(idata)
            set(gca,'YTickLabel',[],'YTick',[])
            xlabel('Frequency (Hz)')
            title(data_titles{idata})
        end
        sgtitle([stim_type_vec{itype} ' - ' channel_names{ichan}])
    end
end