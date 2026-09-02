%% Assign variables
% Metadata
subjid = meta.subjid;
amp_vecs = meta.amp_vecs;
stim_type_vec = meta.stim_type_vec;
stim_freqs = meta.stim_freqs;
my_chans = meta.my_chans;
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;
max_trials = meta.ON_OFF_max_trials;

% Organized data
ON_fft  = org_data.ON_fft;
hydro_ON_time        = org_data.hydro_ON_time;
hydro_OFF_time       = org_data.hydro_OFF_time;
hydro_ON_fft         = org_data.hydro_ON_fft;
hydro_OFF_fft        = org_data.hydro_OFF_fft;
freq_vec             = org_data.freq_vec;
for ifreq = 1:length(stim_freqs)
    tic()
    % Assign current frequency amp_vec
    amp_vec = amp_vecs{ifreq};
    
    %% Plot ON time domain signals
    figure; tiledlayout(5,5,'TileSpacing','tight','Padding','tight')
    for iamp = 1:length(amp_vec)
        nexttile
        cur_hydro_ON_time = squeeze(hydro_ON_time(:,:,iamp,1,ifreq));
        cur_hydro_ON_time(all(isnan(cur_hydro_ON_time), 2), :) = [];
        cmap = parula(size(cur_hydro_ON_time,1));
        for itrial = 1:25:size(cur_hydro_ON_time,1)
            plot(cur_hydro_ON_time(itrial,:), 'Color', [cmap(itrial,:) 0.4])
            hold on;
            xlim([0 2210])
        end
    end
    sgtitle(sprintf("Stim ON Hydrophone %d Hz",stim_freqs(ifreq)))

    %% Plot OFF time domain signals
    figure; tiledlayout(5,5,'TileSpacing','tight','Padding','tight')
    for iamp = 1:length(amp_vec)
        nexttile
        cur_hydro_OFF_time = squeeze(hydro_OFF_time(:,:,iamp,1,ifreq));
        cur_hydro_OFF_time(all(isnan(cur_hydro_OFF_time), 2), :) = [];
        cmap = parula(size(cur_hydro_OFF_time,1));
        for itrial = 1:25:size(cur_hydro_OFF_time,1)
            plot(cur_hydro_OFF_time(itrial,:), 'Color', [cmap(itrial,:) 0.4])
            hold on;
            xlim([0 2210])
        end
    end
    sgtitle(sprintf("Stim OFF Hydrophone %d Hz",stim_freqs(ifreq)))

    %% Plot difference ffts
    for ichan = 2:3
        figure; tiledlayout(5,5,'TileSpacing','tight','Padding','tight')
        for iamp = 1:length(amp_vec)
            nexttile
            cur_ON_hydro_fft = squeeze(hydro_ON_fft(:,:,iamp,1,ifreq));
            cur_ON_AEP_fft = squeeze(ON_fft(:,:,iamp,1,ichan,ifreq));
            my_diff = abs(cur_ON_AEP_fft)- abs(cur_ON_hydro_fft);
            my_diff(all(isnan(my_diff), 2), :) = [];
            cmap = parula(size(my_diff,1));
            for itrial = 1:25:size(my_diff,1)
                plot(freq_vec,my_diff(itrial,:), 'Color',[cmap(itrial,:) 1])
                hold on;
                if stim_freqs(ifreq) > 400
                xlim([300 1000])
                else
                xlim([0 300])
                end
                yline(0,'--')
                xline(stim_freqs(ifreq),'--')
                xline(stim_freqs(ifreq)*2,'--')
            end
        end
        sgtitle(sprintf("AEP-Hydrophone FFT %d Hz Channel %d",stim_freqs(ifreq),ichan))
    end

end