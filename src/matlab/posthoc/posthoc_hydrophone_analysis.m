%% Posthoc Hydrophone Analysis
%% OUTPUT
% MAIN STRUCT
% hydro_results
% SUBFIELDS
% my_noise_floor(trial,amp,freqs)
% my_stim_ON(trial,amp,freqs)

%% Assign variables
% Metadata
subjid = meta.subjid;
amp_vecs = meta.amp_vecs;
subplot_space = [4 5 ; 4 4; 3 3];
[~,largest_idx] = max(cellfun(@length,amp_vecs));
larg_amp_vec = amp_vecs{largest_idx};
stim_type_vec = meta.stim_type_vec;
stim_freqs = meta.stim_freqs;
my_chans = meta.my_chans;
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;
max_trials = meta.ON_OFF_max_trials;
microphone_mV_per_Pa = 3.16;
fs = 44100;

% Organized data
ON_fft  = org_data.ON_fft;
hydro_ON_time        = org_data.hydro_ON_time;
hydro_OFF_time       = org_data.hydro_OFF_time;
hydro_ON_fft         = org_data.hydro_ON_fft;
hydro_OFF_fft        = org_data.hydro_OFF_fft;
freq_vec             = org_data.freq_vec;

% Preallocate
max_amp_length = max(cellfun(@length,amp_vecs));
my_noise_floor = NaN(max_trials*3, max_amp_length, length(stim_freqs));
my_stim_ON = NaN(max_trials*3, max_amp_length, length(stim_freqs));
hydro_results = struct();

for ifreq = 1:length(stim_freqs)
    tic()

    % Assign Target Frequency
    target_freq = stim_freqs(ifreq);

    % Assign current frequency amp_vec
    amp_vec = amp_vecs{ifreq};

    % Calculate noise floor dB Values
    for iamp = 1:length(amp_vec)
        cur_data = squeeze(hydro_OFF_fft(:,:,iamp,1,ifreq));
        cur_data(all(isnan(cur_data),2),:) = [];
        for itrial = 1:size(cur_data,1)
            targ_idx = find(freq_vec == target_freq);
            if freq_vec(targ_idx) ~= target_freq
                keyboard
            end
            cur_trial = cur_data(itrial,targ_idx);
            rms_mV = abs(cur_trial)/sqrt(2);
            rms_Pa = rms_mV/microphone_mV_per_Pa;
            rms_dB = 20*log10(rms_Pa/1e-6); % 1 micro Pa
            % Save RMS measure
            my_noise_floor(itrial,iamp,ifreq) = rms_dB;
        end
    end

    % Calculate stim ON dB Values
    for iamp = 1:length(amp_vec)
        cur_data = squeeze(hydro_ON_fft(:,:,iamp,1,ifreq));
        cur_data(all(isnan(cur_data),2),:) = [];
        for itrial = 1:size(cur_data,1)
            targ_idx = find(freq_vec == target_freq);
            if freq_vec(targ_idx) ~= target_freq
                keyboard
            end
            cur_trial = cur_data(itrial,targ_idx);
            rms_mV = abs(cur_trial)/sqrt(2); % ?
            rms_Pa = rms_mV/microphone_mV_per_Pa;
            rms_dB = 20*log10(rms_Pa/1e-6); % 1 micro Pa
            % Save RMS measure
            my_stim_ON(itrial,iamp,ifreq) = rms_dB;
        end
    end

    % %% Plot OFF time domain signals
    % figure; tiledlayout(subplot_space(ifreq,1),subplot_space(ifreq,2),'TileSpacing','tight','Padding','tight')
    % for iamp = 1:length(amp_vec)
    %     nexttile
    %     cur_data = squeeze(hydro_OFF_time(:,:,iamp,1,ifreq));
    %     cur_data(all(isnan(cur_data), 2), :) = [];
    %     cmap = nebula(size(cur_data,1));
    %     for itrial = 1:25:size(cur_data,1)
    %         cur_trial = cur_data(itrial,:);
    %         % Get rid of nans
    %         cur_trial(isnan(cur_trial)) = [];
    %         % Plot time domain signal
    %         plot(cur_trial, 'Color', [cmap(itrial,:) 0.4])
    %         hold on;
    %         xlim([0 2210])
    %         title(amp_vec(iamp))
    %     end
    % end
    % sgtitle(sprintf("Stim OFF Hydrophone %d Hz",stim_freqs(ifreq)))
    %
    % %% Plot ON time domain signals
    % figure; tiledlayout(subplot_space(ifreq,1),subplot_space(ifreq,2),'TileSpacing','tight','Padding','tight')
    % for iamp = 1:length(amp_vec)
    %     nexttile
    %     cur_data = squeeze(hydro_ON_time(:,:,iamp,1,ifreq));
    %     cur_data(all(isnan(cur_data), 2), :) = [];
    %     cmap = nebula(size(cur_data,1));
    %     for itrial = 1:25:size(cur_data,1)
    %         plot(cur_data(itrial,:), 'Color', [cmap(itrial,:) 0.4])
    %         hold on;
    %         xlim([0 2210])
    %         title(amp_vec(iamp))
    %     end
    % end
    % sgtitle(sprintf("Stim ON Hydrophone %d Hz",stim_freqs(ifreq)))

    % %% Plot difference ffts
    % for ichan = 2:3
    %     figure; tiledlayout(5,5,'TileSpacing','tight','Padding','tight')
    %     for iamp = 1:length(amp_vec)
    %         nexttile
    %         cur_ON_hydro_fft = squeeze(hydro_ON_fft(:,:,iamp,1,ifreq));
    %         cur_ON_AEP_fft = squeeze(ON_fft(:,:,iamp,1,ichan,ifreq));
    %         my_diff = abs(cur_ON_AEP_fft)- abs(cur_ON_hydro_fft);
    %         my_diff(all(isnan(my_diff), 2), :) = [];
    %         cmap = nebula(size(my_diff,1));
    %         for itrial = 1:25:size(my_diff,1)
    %             plot(freq_vec,my_diff(itrial,:), 'Color',[cmap(itrial,:) 1])
    %             hold on;
    %             if stim_freqs(ifreq) > 400
    %             xlim([300 1000])
    %             else
    %             xlim([0 300])
    %             end
    %             yline(0,'--')
    %             xline(stim_freqs(ifreq),'--')
    %             xline(stim_freqs(ifreq)*2,'--')
    %             title(amp_vec(iamp))
    %         end
    %     end
    %     sgtitle(sprintf("AEP-Hydrophone FFT %d Hz Channel %d",stim_freqs(ifreq),ichan))
    % end

end

%% Store results into table
% my_noise_floor(trial,amp,freqs)
% my_stim_ON(trial,amp,freqs)

% Get rid of NaN rows in my_noise_floor and my_stim_ON
keep = ~(all(isnan(my_noise_floor),[2 3]) & all(isnan(my_stim_ON),[2 3]));
my_noise_floor = my_noise_floor(keep,:,:);
my_stim_ON     = my_stim_ON(keep,:,:);

% Preallocate Table Variables
column_name = {'Subj_ID', 'Trial_N','Freq', 'Amp','Val'};
n_row = size(my_noise_floor,1) * sum(cellfun(@length,amp_vecs)); % Need to cover freq*amp_vec rows
hydro_noise = NaN(n_row,5);
hydro_ON = NaN(n_row,5);
irow = 0;

for ifreq = 1:length(stim_freqs)
    cur_freq = stim_freqs(ifreq);
    amp_vec = amp_vecs{ifreq};
    for iamp = 1:length(amp_vec)
        cur_amp = amp_vec(iamp);
        for itrial = 1:size(my_noise_floor,1)
            irow = irow + 1;

            % Get values
            cur_noise = my_noise_floor(itrial,iamp,ifreq);
            cur_ON = my_stim_ON(itrial,iamp,ifreq);

            % Save to table
            hydro_noise(irow,:) = [subjid itrial cur_freq cur_amp cur_noise];
            hydro_ON(irow,:) = [subjid itrial cur_freq cur_amp cur_ON];

        end
    end
end

% Convert to table
hydro_noise = array2table(hydro_noise,'VariableNames',column_name);
hydro_ON    = array2table(hydro_ON,'VariableNames',column_name);

% Get rid of NaNs
hydro_noise(isnan(hydro_noise.Val),:) = [];
hydro_ON(isnan(hydro_ON.Val),:) = [];

% Store in hydro_results
hydro_results.noise = hydro_noise;
hydro_results.ON = hydro_ON;

% Plot Noise floor and stim ON dB Values
figure; tiledlayout(1,length(stim_freqs),'TileSpacing','compact','Padding','compact')
box_width = 0.5*min(diff(larg_amp_vec));

for ifreq = 1:length(stim_freqs)
    cur_color = select_chan_color(ifreq);
    nexttile
    nf = hydro_results.noise(hydro_results.noise.Freq == stim_freqs(ifreq),:);
    on = hydro_results.ON(hydro_results.ON.Freq == stim_freqs(ifreq),:);

    boxchart(nf.Amp, nf.Val, 'BoxWidth', box_width, ...
        'BoxFaceColor', [0.6 0.6 0.6], 'MarkerColor', [0.9 0.9 0.9], ...
        'BoxFaceAlpha', 0.25,'BoxEdgeColor', [0.75 0.75 0.75], 'WhiskerLineColor', [0.75 0.75 0.75])
    hold on
    boxchart(on.Amp, on.Val, 'BoxWidth', box_width, ...
        'BoxFaceColor', cur_color, 'MarkerColor', cur_color)

    xlim([min(larg_amp_vec)-3 max(larg_amp_vec)+3])
    xticks(larg_amp_vec)
    title(sprintf('%d Hz', stim_freqs(ifreq)))
    xlabel('Assigned Stimulus Amplitude (dB)')
    if ifreq == 1
        ylabel('Amplitude at Stimulus Frequency (dB)')
    end
end
linkaxes(findall(gcf,'Type','axes'),'xy')
sgtitle('Stimulus and Noise Floor Amplitude at Stimulus Frequency')