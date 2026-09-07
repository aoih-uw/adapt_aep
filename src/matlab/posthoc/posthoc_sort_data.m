%% Load your data first with load_my_file
function [meta, org_data] = posthoc_sort_data(grand_ex_save, base_dir, save_dir)
%% What this code does:
%
%% Assign Variables
info = grand_ex_save{1,1}.info;
meta.subjid            = info.animal.subject_ID;
meta.exp_type          = info.experiment.exp_type;
if strcmp(meta.exp_type,'Mixed freqs')
    meta.amp_vecs           = info.mixed.test_amplitudes;
    meta.stim_type_vec     = info.mixed.stim_name;
    meta.stim_freqs         = info.mixed.stim_freqs;
    meta.ON_OFF_max_trials = 260;
elseif strcmp(meta.exp_type,'Timed')
    meta.amp_vecs = {info.stimulus.amplitude_spl};
    meta.stim_type_vec = 'trim';
    meta.stim_freqs = info.stimulus.frequency_hz;
    meta.trim_stim_pre_dur_ms = info.stimulus.trim_stim_pre_dur_ms;
    meta.ON_OFF_max_trials = 5000;
end
meta.my_chans          = 1:info.channels.n_channels;
meta.my_chans_name     = info.channels.names;
meta.target_freq_range = 3;
meta.trials_per_block  = info.trials.trials_per_block;
meta.experiment_date = info.experiment.exp_date;
meta.data_path = save_dir;

% Metadata
subjid = meta.subjid;
amp_vecs = meta.amp_vecs;
if strcmp(meta.exp_type,'Mixed freqs')
    [~, largest_amp_vec] = max(cellfun(@numel, amp_vecs));
    stim_type_vec = meta.stim_type_vec;
else
    largest_amp_vec = 1;
    stim_type_vec = meta.stim_type_vec;
end
stim_freqs = meta.stim_freqs;
my_chans = meta.my_chans;
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;

%% Preallocate Vectors
max_rows = meta.ON_OFF_max_trials*3;
n_bins = [];
model_sample_length = [];
low_lim = 0 ; up_lim = 2000;
phase_vec = NaN(max_rows, 1, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(my_chans), length(stim_freqs),'single');
time_vec = NaT(max_rows, 1, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(my_chans), length(stim_freqs),'TimeZone','America/Los_Angeles');

% AEPs
% 2f magnitude bins
ON_2f = NaN(max_rows, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(my_chans), length(stim_freqs),'single');
OFF_2f = NaN(max_rows, length(amp_vecs{largest_amp_vec}), 1, length(my_chans), length(stim_freqs),'single'); % Only valid for ONOFF stimuli

% FFTs- allocated on first trial, once the true bin count is known
freq_vec = []; ON_fft = []; OFF_fft = [];

% Hydrophone
hydro_ds_rate = 4;
% Time domain (77632 # of samples of longest stimuli /4 to downsample)
hydro_ON_time = NaN(max_rows, 77632/hydro_ds_rate, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(stim_freqs),'single');
hydro_OFF_time = NaN(max_rows, 77632/hydro_ds_rate, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(stim_freqs),'single');

% FFTs
hydro_ON_fft = [];
hydro_OFF_fft = [];

%% Begin searching through datasets
for iname = 1:length(grand_ex_save)
    tic()
    fprintf('%d\n', iname)
    % Load in vars necessary for processing data
    latency_samples = grand_ex_save{1,iname}.info.recording.latency_samples;
    fs = grand_ex_save{1,iname}.info.recording.sampling_rate_hz;

    % Get number of batches
    n_batches = size(grand_ex_save{1,iname}.raw_signals,2);

    %% IDENTIFY FIRST/LAST BATCH FOR EACH STIM TYPE
    if strcmp(meta.exp_type,'Mixed freqs')
        collect_attempt_vec = cat(1,grand_ex_save{1,iname}.block_level_info(1:n_batches).collection_attempts);
        collect_attempt_vec = [collect_attempt_vec ; 0]; % To account for times where the very last batch was a retry and had enough trials by then, but there are no batches after so there won't be a negative value
        att_diff = diff(collect_attempt_vec);
        last_batch_loc = find(att_diff < 0);
        first_batch_loc = last_batch_loc + att_diff(last_batch_loc); % By adding the neg diff value onto its own index, we can find the idx value of the first associated batch
        % Don't mistake the intermediate block values as single batches!
        in_mult = arrayfun(@(f,l) f:l, first_batch_loc, last_batch_loc, 'UniformOutput', false);
        mult_batch_locs = [first_batch_loc last_batch_loc]; % Matrix showing first batch and corresponding last batch
        single_batch_locs = setdiff(1:n_batches, [in_mult{:}])';
    elseif strcmp(meta.exp_type,'Timed')
        mult_batch_locs = [];
        single_batch_locs = 1:20;
    end
    for ichan = 1:length(my_chans)
        cur_chan = my_chans(ichan);
        row_idx = 1; % Reset after every channel
        for ibatch = 1:n_batches

            %% GET KEPT TRIALS
            [kept_trials, kept_jitter, kept_phase, kept_hydro, kept_time] = get_kept_trials(grand_ex_save, iname, ...
                ibatch, cur_chan, single_batch_locs, mult_batch_locs,trials_per_block,ichan==1);

            % Ensure equal phases
            if sum(kept_phase) ~= 0
                keyboard
            end

            %% GET CURRENT BATCH META DATA
            if strcmp(meta.exp_type,'Mixed freqs')
                cur_freq = grand_ex_save{1,iname}.block_level_info(ibatch).stim_freq;
                freq_idx = find(info.mixed.stim_freqs == cur_freq);
            elseif strcmp(meta.exp_type,'Timed')
                cur_freq = stim_freqs;
                freq_idx = 1;
            end
            stimulus = grand_ex_save{1,iname}.info.stimulus(freq_idx).waveform;
            cur_amp_vec = amp_vecs{freq_idx};
            ramp_duration_samples = grand_ex_save{1,iname}.info.stimulus(freq_idx).ramp_duration_ms/1e3*fs;
            trim_stim_pre_dur_ms = grand_ex_save{1,iname}.info.stimulus(freq_idx).trim_stim_pre_dur_ms;

            %% Assign target frequency
            % target_freq = 130;
            target_freq = cur_freq*2;

            if ~isempty(kept_trials)
                % Preallocate
                n_trials = size(kept_trials,1);
                temp_ON_2f = NaN(n_trials,1);
                temp_OFF_2f = NaN(n_trials,1);

                %% Get indices for current amp/stim type
                if strcmp(meta.exp_type,'Mixed freqs')
                    amp_idx = find(cur_amp_vec == round(grand_ex_save{1,iname}.block_level_info(ibatch).stim_amp)); % Round for sensitive doubles
                    stim_type_idx = find(strcmp(stim_type_vec, ...
                        grand_ex_save{1,iname}.block_level_info(ibatch).stim_type));
                    cur_stim_type = grand_ex_save{1,iname}.block_level_info(ibatch).stim_type;
                elseif strcmp(meta.exp_type,'Timed')
                    amp_idx = 1;
                    stim_type_idx = 1;
                    cur_stim_type = stim_type_vec;
                end

                % Check if nothing matches
                if isempty(amp_idx) || isempty(stim_type_idx)
                    keyboard
                end

                %% Find the first full NaN row to start populating from
                start_row = find(isnan(ON_2f(:,amp_idx,stim_type_idx,ichan,freq_idx)), 1, 'first');

                %% CHECKS
                if isempty(start_row)
                    error('organize_data:Full', ...
                        'ON_2f row capacity (%d) exhausted at amp %d, type %d, chan %d, freq %d', ...
                        size(ON_2f,1), amp_idx, stim_type_idx, ichan, freq_idx);
                end

                % There must be no filled rows beyond the first empty one
                if any(~isnan(ON_2f(start_row:end,amp_idx,stim_type_idx,ichan,freq_idx)))
                    error('organize_data:RowGap', ...
                        'Gap in ON_2f rows at start_row %d (amp %d, type %d, chan %d, freq %d)', ...
                        start_row, amp_idx, stim_type_idx, ichan, freq_idx);
                end

                %% ASSIGN ROW RANGE FOR CURRENT BATCH
                row_range = start_row:start_row+n_trials-1;
                if row_range(end) > size(ON_2f,1)
                    error('organize_data:Overflow', ...
                        'Batch of %d trials overflows row capacity %d', n_trials, size(ON_2f,1));
                end

                %% Extract ON/OFF Time Domain Signals
                if strcmp(cur_stim_type, 'trim')
                    % AEP signal
                    [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
                        kept_trials, 0, fs, ...
                        latency_samples, length(stimulus), ramp_duration_samples,...
                        trim_stim_pre_dur_ms,...
                        kept_jitter);

                    % Hydrophone
                    if ichan == 1
                        [hydro_ON_time_tmp , hydro_OFF_time_tmp] = extract_stim_ON_OFF( ...
                            kept_hydro, 0, fs, ...
                            latency_samples, length(stimulus), ramp_duration_samples,...
                            trim_stim_pre_dur_ms,...
                            kept_jitter);
                    end
                else % It is ONOFF
                    % AEP signal
                    [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
                        kept_trials, 1, fs, ...
                        latency_samples, length(stimulus), ramp_duration_samples,...
                        [],...
                        kept_jitter);

                    % Hydrophone
                    if ichan == 1
                        [hydro_ON_time_tmp , hydro_OFF_time_tmp] = extract_stim_ON_OFF( ...
                            kept_hydro, 1, fs, ...
                            latency_samples, length(stimulus), ramp_duration_samples,...
                            [],...
                            kept_jitter);
                    end

                end

                %% Save Hydrophone time domain signals
                if ichan == 1
                    for itrial = 1:size(hydro_ON_time_tmp,1)
                        tmp_ON  = decimate(double(hydro_ON_time_tmp(itrial,:)), hydro_ds_rate);
                        tmp_OFF = decimate(double(hydro_OFF_time_tmp(itrial,:)), hydro_ds_rate);
                        hydro_ON_time(row_range(itrial),1:numel(tmp_ON),amp_idx,stim_type_idx,freq_idx)   = tmp_ON;
                        hydro_OFF_time(row_range(itrial),1:numel(tmp_OFF),amp_idx,stim_type_idx,freq_idx) = tmp_OFF;
                    end
                end

                %% Save phase_vector
                phase_vec(row_range, 1, amp_idx, stim_type_idx, ichan,freq_idx) = kept_phase;
                time_vec(row_range,1,amp_idx,stim_type_idx,ichan,freq_idx) = kept_time;

                %% Calculate stim ON/OFF ffts
                for itrial = 1:n_trials
                    %% Stim ON
                    % AEP
                    cur_trial = stim_ON(itrial,:);
                    % Ensure no NaNs
                    if any(isnan(cur_trial))
                        keyboard
                    end

                    % Hydrophone
                    if ichan == 1
                        cur_hydro_trial = hydro_ON_time_tmp(itrial,:);
                        % Ensure no NaNs
                        if any(isnan(cur_hydro_trial))
                            keyboard
                        end
                    end

                    % Save very first sample length of stim_ON to ensure all
                    % other stim ons have the same length
                    if isempty(model_sample_length)
                        model_sample_length = size(cur_trial,2);
                    else
                        if size(cur_trial,2) ~= model_sample_length
                            keyboard
                            error('organize_data:ONLength', ...
                                ['stim_ON length %d ~= expected %d ' ...
                                '(file %d, batch %d, chan %d, trial %d)'], ...
                                size(cur_trial,2), model_sample_length, ...
                                iname, ibatch, ichan, itrial);
                        end
                    end

                    %% Calculate ON fft
                    [tmp_freq_vec, tmp_fft_vals] = calc_fft_complex(cur_trial, fs); % AEP
                    if ichan == 1
                        [hydro_tmp_freq_vec, hydro_tmp_fft_vals] = calc_fft_complex(cur_hydro_trial, fs); % Hydrophone
                    end

                    % Check that freq_ves are the same for AEPs and
                    % Hydrophone signals
                    if ichan == 1 && ~isequal(tmp_freq_vec,hydro_tmp_freq_vec)
                        error('freq_vecs of aep and hydrophone signals are not the same')
                    end

                    %% AEP Signal: Get the bin at the target frequency
                    [temp_ON_2f(itrial), ~] = ...
                        find_fft_bins(target_freq, target_freq_range, tmp_fft_vals, tmp_freq_vec);

                    %% Save to mega fft structure for waterfall
                    freq_vec_range = find(tmp_freq_vec >=low_lim & tmp_freq_vec <= up_lim);
                    select_freq_vec = tmp_freq_vec(freq_vec_range);

                    % Filter fft values to desired range
                    select_fft_vals = tmp_fft_vals(freq_vec_range); % AEP
                    if ichan == 1
                        select_hydro_fft_vals = hydro_tmp_fft_vals(freq_vec_range); % Hydrophone
                    end

                    %% Preallocate FFT vectors
                    if isempty(n_bins)
                        n_bins = numel(freq_vec_range);
                        % AEP
                        ON_fft  = NaN(max_rows, n_bins, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(my_chans), length(stim_freqs),'single');
                        OFF_fft = NaN(max_rows, n_bins, length(amp_vecs{largest_amp_vec}), 1, length(my_chans), length(stim_freqs),'single');

                        % Hydrophone
                        if ichan == 1
                            hydro_ON_fft = NaN(max_rows, n_bins, length(amp_vecs{largest_amp_vec}), length(stim_type_vec), length(stim_freqs),'single');
                            hydro_OFF_fft = NaN(max_rows, n_bins, length(amp_vecs{largest_amp_vec}), 1, length(stim_freqs),'single');
                        end
                    elseif numel(freq_vec_range) ~= n_bins
                        error('organize_data:BinCount', ...
                            'FFT bin count %d ~= expected %d (fs=%g, N=%d, file %d, batch %d)', ...
                            numel(freq_vec_range), n_bins, fs, numel(cur_trial), iname, ibatch);
                    end

                    %% Save fft values
                    ON_fft(row_range(itrial), 1:n_bins, amp_idx, stim_type_idx, ichan,freq_idx) = select_fft_vals; % AEP
                    if ichan == 1
                        hydro_ON_fft(row_range(itrial), 1:n_bins, amp_idx, stim_type_idx,freq_idx) = select_hydro_fft_vals; % Hydrophone
                    end

                    %% Calculate FFT for Stim OFF
                    % AEP
                    cur_trial_OFF = stim_OFF(itrial,:);
                    if any(isnan(cur_trial_OFF))
                        error('organize_data:OFFNaN', ...
                            'NaNs in stim_OFF (file %d, batch %d, chan %d, trial %d)', ...
                            iname, ibatch, ichan, itrial);
                    end

                    % Hydrophone
                    if ichan == 1
                        cur_hydro_OFF = hydro_OFF_time_tmp(itrial,:);
                        if any(isnan(cur_hydro_OFF))
                            error('organize_data:OFFNaN', ...
                                'NaNs in stim_OFF (file %d, batch %d, chan %d, trial %d)', ...
                                iname, ibatch, ichan, itrial);
                        end
                    end

                    % Check if we get the expected sample length
                    if strcmp(meta.exp_type,'Mixed freqs') & (size(cur_trial_OFF,2) ~= model_sample_length)
                        error('organize_data:OFFLength', ...
                            'stim_OFF length %d ~= expected %d', ...
                            size(cur_trial_OFF,2), model_sample_length);
                    end

                    %% CALCULATE OFF FFT
                    % AEP
                    [tmp_freq_vec_OFF, tmp_fft_vals_OFF] = calc_fft_complex(cur_trial_OFF, fs);
                    freq_vec_range_OFF = find(tmp_freq_vec_OFF >= low_lim & tmp_freq_vec_OFF <= up_lim);
                    select_freq_vec_OFF = tmp_freq_vec_OFF(freq_vec_range_OFF);

                    % Hydrophone
                    if ichan == 1
                        [tmp_hydro_freq_vec_OFF, tmp_hydro_fft_vals_OFF] = calc_fft_complex(cur_hydro_OFF, fs);
                        freq_vec_range_hydro_OFF = find(tmp_hydro_freq_vec_OFF >= low_lim & tmp_hydro_freq_vec_OFF <= up_lim);
                        select_freq_vec_hydro_OFF = tmp_hydro_freq_vec_OFF(freq_vec_range_hydro_OFF);
                    end

                    % Check for size mismatches between ON/OFF periods
                    if strcmp(meta.exp_type,'Mixed freqs') && (~isequal(size(cur_trial), size(cur_trial_OFF)) || ...
                            (~isequal(select_freq_vec_OFF, select_freq_vec)))
                        error('organize_data:ONOFFMismatch', ...
                            'ON/OFF window or frequency axis mismatch (file %d, batch %d, chan %d, trial %d)', ...
                            iname, ibatch, ichan, itrial);
                    end

                    % Timed OFF stimuli are shorter so need to account for
                    % this in the preallocation
                    if strcmp(meta.exp_type,'Timed')
                        off_n_bins = length(tmp_fft_vals_OFF(freq_vec_range_OFF));
                        % Save OFF fft values
                        OFF_fft(row_range(itrial),1:off_n_bins,amp_idx,1,ichan,freq_idx) = ...
                            tmp_fft_vals_OFF(freq_vec_range_OFF); % AEP
                        if ichan == 1
                            hydro_OFF_fft(row_range(itrial),1:off_n_bins,amp_idx,1,freq_idx) = ...
                                tmp_hydro_fft_vals_OFF(freq_vec_range_hydro_OFF); % Hydrophone
                        end
                    elseif strcmp(meta.exp_type,'Mixed freqs')
                        % Save OFF fft values
                        OFF_fft(row_range(itrial),1:n_bins,amp_idx,1,ichan,freq_idx) = ...
                            tmp_fft_vals_OFF(freq_vec_range_OFF); % AEP
                        if ichan == 1
                            hydro_OFF_fft(row_range(itrial),1:n_bins,amp_idx,1,freq_idx) = ...
                                tmp_hydro_fft_vals_OFF(freq_vec_range_hydro_OFF); % Hydrophone
                        end
                    end

                    % Get OFF target frequency bin
                    if strcmp(meta.exp_type,'Timed')
                        target_freq_range = diff(tmp_freq_vec_OFF(1:2));
                    end
                    [temp_OFF_2f(itrial), ~] = ...
                        find_fft_bins(target_freq, target_freq_range, tmp_fft_vals_OFF, tmp_freq_vec_OFF);
                end

                %% Populate ON_2f and OFF_2f bin magnitude matrices
                % Check that all cells have been filled
                if any(isnan(temp_ON_2f)) || (any(isnan(temp_OFF_2f)) & strcmp(cur_stim_type, 'ONOFF'))
                    keyboard
                end

                ON_2f(row_range,amp_idx,stim_type_idx,ichan,freq_idx) ...
                    = temp_ON_2f;

                if strcmp(cur_stim_type, 'ONOFF')
                    OFF_2f(row_range,amp_idx,1,ichan,freq_idx) ...
                        = temp_OFF_2f;
                end

            end
        end
    end
    toc()
end

%% Organize data into org_data
% AEP
org_data.ON_2f        = ON_2f;
org_data.OFF_2f       = OFF_2f;
org_data.freq_vec     = select_freq_vec;
org_data.freq_vec_OFF = select_freq_vec_hydro_OFF;
org_data.ON_fft  = ON_fft;
org_data.OFF_fft = OFF_fft;
org_data.phase_vec    = phase_vec;
org_data.time_vec = time_vec;

% Hydrophone
org_data.hydro_ds_rate  = hydro_ds_rate;
org_data.hydro_ON_time  = hydro_ON_time;
org_data.hydro_OFF_time = hydro_OFF_time;
org_data.hydro_ON_fft   = hydro_ON_fft;
org_data.hydro_OFF_fft  = hydro_OFF_fft;

% Save organized data
cd(save_dir)
save(sprintf('subject_%d_%s_%s', subjid, meta.exp_type,datestr(now,'yyyymmdd')), ...
    'meta', 'org_data','-v7.3')
