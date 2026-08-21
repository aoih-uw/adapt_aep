% Function posthoc_waterfall
clearvars -except grand_ex_save meta org_data

% Assign vars
% Metadata
subjid = meta.subjid;
amp_vecs = meta.amp_vecs;
stim_type_vec = meta.stim_type_vec;
if isfield(meta, 'stim_freqs')
    stim_freqs = meta.stim_freqs;
else
    stim_freqs = meta.stim_freq;
end
my_chans = meta.my_chans;
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;

% Organized data
freq_vec     = org_data.freq_vec;
ON_fft_vals  = org_data.ON_fft_vals;
OFF_fft_vals = org_data.OFF_fft_vals;
phase_vec    = org_data.phase_vec;

% Function specific vars
data_titles = {'Stim ON','Stim OFF','Stim ON-OFF'};

% Look at which type of stimuli we are working with to know how many trials
% to include
for ifreq = 1:length(stim_freqs)
    amp_vec = amp_vecs{ifreq};
    for itype = 1:length(stim_type_vec)
        % Select trial number
        if strcmp(stim_type_vec{itype},'trim')
            trials_in_avg = 1024;
        else
            trials_in_avg = 256;
        end

        for ichan = 1:length(my_chans)
            % Select channel colors
            cur_color = select_chan_color(ichan);
            % Make figure
            figure;
            if strcmp(stim_type_vec{itype},'trim')
                tiledlayout(1,1,"TileSpacing","tight","Padding","tight")
            else
                tiledlayout(1,3,"TileSpacing","tight","Padding","tight")
            end
            cumu_offset = zeros(1,3);

            % Loop through amplitudes
            for iamp = 1:length(amp_vec)
                % Get current amplitude, stim type, and chanel data
                cur_freq_vec = squeeze(freq_vec(:,:,iamp, itype, ichan,ifreq));
                cur_fft_vals_ON  = squeeze(ON_fft_vals(:,:,iamp, itype, ichan,ifreq));
                if strcmp(stim_type_vec{itype},'ONOFF')
                    cur_fft_vals_OFF = squeeze(OFF_fft_vals(:,:,iamp, 1, ichan,ifreq));
                else
                    cur_fft_vals_OFF = [];
                end
                cur_phase_vec = squeeze(phase_vec(:,:,iamp,itype,ichan,ifreq));

                % Remove NaN rows that were extras for preallocation
                nan_rows = any(isnan(cur_freq_vec),2) | any(isnan(cur_fft_vals_ON),2);
                cur_freq_vec(nan_rows,:) = [];
                cur_fft_vals_ON(nan_rows,:) = [];
                if strcmp(stim_type_vec{itype},'ONOFF')
                    cur_fft_vals_OFF(nan_rows,:) = [];
                end
                cur_phase_vec(nan_rows,:) = [];

                % Ensure same phases
                phase_types = unique(cur_phase_vec);
                n_per_phase = trials_in_avg / length(phase_types);
                rand_select = [];
                for iphase = 1:length(phase_types)
                    cur_phase_idx = find(cur_phase_vec == phase_types(iphase));
                    my_rand_phase_idx = randperm(length(cur_phase_idx), n_per_phase);
                    rand_select = [rand_select ; cur_phase_idx(my_rand_phase_idx)];
                end
                if sum(cur_phase_vec(rand_select)) ~= 0
                    keyboard
                end

                % Apply the random idx selection
                select_trials_ON = cur_fft_vals_ON(rand_select,:);
                if strcmp(stim_type_vec{itype},'ONOFF')
                    select_trials_OFF = cur_fft_vals_OFF(rand_select,:);
                    diff_vec = select_trials_ON - select_trials_OFF;
                    cur_mean = cat(1, abs(mean(select_trials_ON,1)), abs(mean(select_trials_OFF,1)), abs(mean(diff_vec,1)));
                else
                    cur_mean = abs(mean(select_trials_ON,1));
                end

                for idata = 1:size(cur_mean,1)
                    nexttile(idata); hold on;
                    plot(cur_freq_vec(1,:), cur_mean(idata,:)+cumu_offset(idata), 'LineWidth',2, 'Color',cur_color)
                    text(105, cur_mean(idata,1)+cumu_offset(idata), num2str(amp_vec(iamp)), 'Color',cur_color)
                    cumu_offset(idata) = cumu_offset(idata) + max(cur_mean(idata,:));
                    xlim([0 1000])
                    xline(stim_freqs(ifreq)*2,'--','LineWidth',0.25)
                    xline(stim_freqs(ifreq)+30,'--','LineWidth',0.25)
                    xline(stim_freqs(ifreq)-30,'--','LineWidth',0.25)
                end
            end

            for idata = 1:size(cur_mean,1)
                nexttile(idata)
                set(gca,'YTickLabel',[],'YTick',[])
                xlabel('Frequency (Hz)')
                title(data_titles{idata})
            end
            sgtitle(sprintf('%s - %s - %s Hz',stim_type_vec{itype}, my_chans_name{ichan}, string(stim_freqs(ifreq))));
        end
    end
end
