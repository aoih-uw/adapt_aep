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
fs = org_data.hydro_fs;
ds_rate = 2;
max_rows = meta.ON_OFF_max_trials*2;
latency_samples = 2118;

%% Amplitude vec
amp_vecs = meta.amp_vecs;
if strcmp(meta.exp_type,'Mixed freqs')
    [~, largest_amp_vec] = max(cellfun(@numel, amp_vecs));
    stim_type_vec = meta.stim_type_vec;
else
    keyboard
end

% Preallocate
samp_len = 8820;
hydro_ON_time = NaN(max_rows, samp_len, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(stim_freqs),'single');
hydro_OFF_time = NaN(max_rows, samp_len, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(stim_freqs),'single');

hydro_ON_fft = NaN(max_rows,(samp_len/4)+1,length(amp_vecs{largest_amp_vec}),1,length(stim_freqs));
hydro_OFF_fft = NaN(max_rows,(samp_len/4)+1,length(amp_vecs{largest_amp_vec}),1,length(stim_freqs));
freq_vec_vec = NaN(length(stim_freqs),(samp_len/4)+1);

all_1f_bin = NaN(max_rows,length(amp_vecs{largest_amp_vec}),length(stim_freqs));
all_30_bin = NaN(max_rows,length(amp_vecs{largest_amp_vec}),length(stim_freqs));

my_noise_floor = NaN(max_rows,length(amp_vecs{largest_amp_vec}),length(stim_freqs));
my_stim_ON  = NaN(max_rows,length(amp_vecs{largest_amp_vec}),length(stim_freqs));
ON_30 = NaN(max_rows,length(amp_vecs{largest_amp_vec}),length(stim_freqs));
OFF_30 = NaN(max_rows,length(amp_vecs{largest_amp_vec}),length(stim_freqs));

% Organized data
ON_fft  = org_data.ON_fft;
hydro_time = org_data.hydro_time;
jitter_vec = org_data.jitter_vec;
ramp_duration_samples = meta.ramp_duration_samples;

%% Whole signal analysis
for ifreq = 1:size(hydro_time,5)
    cur_amp_vec = amp_vecs{ifreq};
    mid_idx = round(length(cur_amp_vec)/2);
    figure;tiledlayout(3,2,'TileSpacing','tight','Padding','tight')
    for iamp = 1:numel(cur_amp_vec)
        cur_set = hydro_time(:,:,iamp,1,ifreq);
        cur_set(all(isnan(cur_set),2),:) = [];

        % Get magnitude at stimulus frequency bin
        for itrial = 1:size(cur_set,1)
            cur_trial = cur_set(itrial,:);
            cur_trial(isnan(cur_trial)) = [];

            % Calculate fft
            [freq_vec, fft_vals] = ...
                calc_fft_complex(cur_trial, fs);

            % Find bin
            % Stimulus frequency
            [~,idx] = min(abs(freq_vec-stim_freqs(ifreq)));
            all_1f_bin(itrial,iamp,ifreq) = fft_vals(idx);
            
            % 30 Hz
            [~,idx] = min(abs(freq_vec-30));
            all_30_bin(itrial,iamp,ifreq) = fft_vals(idx);

        end

        % Plotting
        my_idx = randperm(size(cur_set,1),1);
        cur_sub_set = cur_set(my_idx,:);
        if ismember(iamp, [1 mid_idx length(cur_amp_vec)])
            cur_color = select_chan_color(ifreq);
            nexttile
            % Time domain signal
            for itrial = 1:size(cur_sub_set,1)
                x_vec = linspace(0,length(cur_sub_set(itrial,:))/fs,length(cur_sub_set(itrial,:)));
                plot(x_vec,cur_sub_set(itrial,:),'Color',cur_color); hold on;
            end
            title(sprintf('%g dB',cur_amp_vec(iamp)))
            
            % FFT
            nexttile
            my_idx = randperm(size(cur_set,1),10);
            cur_sub_set = cur_set(my_idx,:);
            for itrial = 1:size(cur_sub_set,1)
                cur_trial = cur_sub_set(itrial,:);
                cur_trial(isnan(cur_trial)) = [];
                % Calculate fft
                [freq_vec, fft_vals] = ...
                    calc_fft_complex(cur_trial, fs);
                plot(freq_vec,abs(fft_vals),'Color',cur_color); hold on;
            end
            xlim([1 stim_freqs(ifreq)+50])
            xline(30)
            xline(stim_freqs(ifreq))
        end
    end
    sgtitle(sprintf('%g Hz',stim_freqs(ifreq)))
end

%% Summary stats
figure;
h = tiledlayout(numel(stim_freqs),2,'TileSpacing','tight','Padding','tight');
for ifreq = 1:size(hydro_time,5)
    cur_color = select_chan_color(ifreq);
    cur_amp_vec = amp_vecs{ifreq};
    cur_1f = squeeze(all_1f_bin(:,1:length(cur_amp_vec),ifreq));
    cur_30 = squeeze(all_30_bin(:,1:length(cur_amp_vec),ifreq));
    x_vec = repmat(cur_amp_vec(:)', size(cur_1f,1), 1);

    % Get dB RMS
    % 1f
    rms_mV = abs(cur_1f)./sqrt(2);
    rms_Pa = rms_mV./microphone_mV_per_Pa;
    cur_1f = 20.*log10(rms_Pa./1e-6); % 1 micro Pa

    % 30 Hz
    rms_mV = abs(cur_30)./sqrt(2);
    rms_Pa = rms_mV./microphone_mV_per_Pa;
    cur_30 = 20.*log10(rms_Pa./1e-6); % 1 micro Pa

    nexttile
    boxchart(x_vec(:),cur_1f(:),'BoxFaceColor',cur_color,'JitterOutliers','on','MarkerColor',cur_color)
    xticks(cur_amp_vec)
    xticklabels(string(cur_amp_vec))
    title('1f')
    xlabel('Assigned Amplitude (dB SPL)')
    ylabel('Measured Amplitude (dB SPL)')
    
    nexttile
    boxchart(x_vec(:),cur_30(:),'BoxFaceColor',cur_color,'JitterOutliers','on','MarkerColor',cur_color)
    xticks(cur_amp_vec)
    xticklabels(string(cur_amp_vec))
    title('30 Hz')
    xlabel('Assigned Amplitude (dB SPL)')
    ylabel('Measured Amplitude (dB SPL)')
end
sgtitle('Non trimmed hydrophone signal amplitude at stimulus frequency and 30 Hz')
linkaxes(findobj(h,'Type','axes'),'x')

%% Separate into different periods
for ifreq = 1:size(hydro_time,5)
    cur_amp_vec = amp_vecs{ifreq};
    for iamp = 1:numel(cur_amp_vec)
        cur_set = hydro_time(:,:,iamp,1,ifreq);
        non_nan_idx = all(isnan(cur_set),2);
        cur_set(non_nan_idx,:) = [];
        cur_jitter = jitter_vec(:,1,iamp,1,1,ifreq);
        cur_jitter(non_nan_idx,:) = [];
        ramp_duration_samples = meta.ramp_duration_samples(ifreq);
        % Extract ON OFF
        % Downsampled the hydrophone signals when saving so also
        % downsample all of the input arguments to extract_stim_ON_OFF
        [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
            cur_set, 1, fs, ...
            ceil(latency_samples/ds_rate), ceil(meta.full_amp_samples(ifreq)/ds_rate), ...
            ceil(meta.ramp_duration_samples(ifreq)/ds_rate),[], ceil(cur_jitter/ds_rate));

        hydro_ON_time(1:size(stim_ON,1),1:size(stim_ON,2),iamp,1,ifreq) = stim_ON;
        hydro_OFF_time(1:size(stim_OFF,1),1:size(stim_OFF,2),iamp,1,ifreq) = stim_OFF;

        % Calculate fft by period
        for itrial = 1:size(cur_set,1)
            % ON
            [freq_vec, tmp] = ...
                calc_fft_complex(stim_ON(itrial,:), fs);
            hydro_ON_fft(itrial,1:length(tmp),iamp,1,ifreq) = tmp;
            freq_vec_vec(ifreq,1:length(tmp)) = freq_vec;

            % OFF
            [~, tmp] = ...
                calc_fft_complex(stim_OFF(itrial,:), fs);
            hydro_OFF_fft(itrial,1:length(tmp),iamp,1,ifreq) = tmp;
        end
    end
end

%% Per period analysis
% Preallocate
hydro_results = struct();

for ifreq = 1:length(stim_freqs)
    tic()
    % Assign Target Frequency
    target_freq = stim_freqs(ifreq);
    % Assign current frequency amp_vec
    amp_vec = amp_vecs{ifreq};
    cur_freq_vec = freq_vec_vec(ifreq,:);
    cur_freq_vec(isnan(cur_freq_vec)) = [];

    % Calculate noise floor dB Values
    for iamp = 1:length(amp_vec)
        if ndims(hydro_OFF_fft) > 2
            cur_data = squeeze(hydro_OFF_fft(:,:,iamp,1,ifreq));
        else
            cur_data = hydro_OFF_fft;
        end
        cur_data(all(isnan(cur_data),2),:) = [];

        % Stim Freq OFF
        for itrial = 1:size(cur_data,1)
            [~,targ_idx] = min(abs(cur_freq_vec - target_freq));
            cur_trial = cur_data(itrial,targ_idx);
            rms_mV = abs(cur_trial)/sqrt(2);
            rms_Pa = rms_mV/microphone_mV_per_Pa;
            rms_dB = 20*log10(rms_Pa/1e-6); % 1 micro Pa
            % Save RMS measure
            my_noise_floor(itrial,iamp,ifreq) = rms_dB;
        end

        % 30 Hz OFF
        for itrial = 1:size(cur_data,1)
            [~,targ_idx] = min(abs(cur_freq_vec - 30));
            cur_trial = cur_data(itrial,targ_idx);
            rms_mV = abs(cur_trial)/sqrt(2);
            rms_Pa = rms_mV/microphone_mV_per_Pa;
            rms_dB = 20*log10(rms_Pa/1e-6); % 1 micro Pa
            % Save RMS measure
            OFF_30(itrial,iamp,ifreq) = rms_dB;
        end
    end

    % Calculate stim ON dB Values
    for iamp = 1:length(amp_vec)
        cur_data = squeeze(hydro_ON_fft(:,:,iamp,1,ifreq));
        cur_data(all(isnan(cur_data),2),:) = [];

        % Stim Freq ON
        for itrial = 1:size(cur_data,1)
            [~,targ_idx] = min(abs(cur_freq_vec - target_freq));
            cur_trial = cur_data(itrial,targ_idx);
            rms_mV = abs(cur_trial)/sqrt(2); % ?
            rms_Pa = rms_mV/microphone_mV_per_Pa;
            rms_dB = 20*log10(rms_Pa/1e-6); % 1 micro Pa
            % Save RMS measure
            my_stim_ON(itrial,iamp,ifreq) = rms_dB;
        end

        % 30 Hz ON
        for itrial = 1:size(cur_data,1)
            [~,targ_idx] = min(abs(cur_freq_vec - 30));
            cur_trial = cur_data(itrial,targ_idx);
            rms_mV = abs(cur_trial)/sqrt(2); % ?
            rms_Pa = rms_mV/microphone_mV_per_Pa;
            rms_dB = 20*log10(rms_Pa/1e-6); % 1 micro Pa
            % Save RMS measure
            ON_30(itrial,iamp,ifreq) = rms_dB;
        end
    end
end

%% Store results into table
% my_noise_floor(trial,amp,freqs)
% my_stim_ON(trial,amp,freqs)

% Get rid of NaN rows in my_noise_floor and my_stim_ON
keep = ~(all(isnan(my_noise_floor),[2 3]) & all(isnan(my_stim_ON),[2 3]));
my_noise_floor = my_noise_floor(keep,:,:);
my_stim_ON     = my_stim_ON(keep,:,:);
ON_30 = ON_30(keep,:,:);
OFF_30 = OFF_30(keep,:,:);

% Preallocate Table Variables
column_name = {'Subj_ID', 'Trial_N','Freq', 'Amp','ON_1f','OFF_1f', 'ON_30Hz', 'OFF_30Hz'};
n_row = size(my_noise_floor,1) * sum(cellfun(@length,amp_vecs)); % Need to cover freq*amp_vec rows
hydro_results = NaN(n_row,8);
irow = 0;

% Save to table
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
            cur_ON_30 = ON_30(itrial,iamp,ifreq);
            cur_OFF_30 = OFF_30(itrial,iamp,ifreq);

            % Save to table
            hydro_results(irow,:) = [subjid itrial cur_freq cur_amp cur_ON cur_noise cur_ON_30 cur_OFF_30];

        end
    end
end

% Convert to table
hydro_results = array2table(hydro_results,'VariableNames',column_name);

% Get rid of NaNs
hydro_results(isnan(hydro_results.ON_1f),:) = [];

%% Plot 
cmap = [tableau_10('blue'); tableau_10('orange')];
for f = unique(hydro_results.Freq)'
    T = hydro_results(hydro_results.Freq == f,:);
    x = [T.Amp; T.Amp];
    cond = categorical([repmat("ON",height(T),1); repmat("OFF",height(T),1)]);

    figure; colororder(cmap); tiledlayout(1,2)

    nexttile
    boxchart(x,[T.ON_1f; T.OFF_1f],'GroupByColor',cond,'JitterOutliers','on')
    title('1f'); xlabel('Amp (dB SPL)'); ylabel('Measured (dB SPL)'); legend

    nexttile
    boxchart(x,[T.ON_30Hz; T.OFF_30Hz],'GroupByColor',cond,'JitterOutliers','on')
    title('30 Hz'); xlabel('Amp (dB SPL)'); ylabel('Measured (dB SPL)'); legend

    sgtitle(f + " Hz")
    linkaxes
end