%% Load your data first with load_my_file
%% Sort through data

%% Assign Variables
clearvars -except grand_ex_save
amp_vec = 95:3:140;
stim_type_vec = {'trim', 'ONOFF'};
my_chans = [2,3,4]; % 2 = 2mm, 3 = 4mm, 4 = subcut
target_freq_range =  3; % for fft bin finding calculations
isubj = 1;

%% Preallocate
% 2f magnitude bins
ON_2f = NaN(2000, length(amp_vec), length(stim_type_vec), length(my_chans),'single');
OFF_2f = NaN(2000, length(amp_vec), 1, length(my_chans),'single'); % Only valid for ONOFF stimuli

% FFTs
freq_vec = NaN(2000, 201, length(amp_vec), length(stim_type_vec), length(my_chans),'single');
ON_fft_vals = NaN(2000, 201, length(amp_vec), length(stim_type_vec), length(my_chans),'single');
OFF_fft_vals = NaN(2000, 201, length(amp_vec), 1, length(my_chans),'single'); % Only valid for ONOFF stimuli
low_lim= 0 ; up_lim = 1000; % Hz
phase_vec = NaN(2000, 1, length(amp_vec), length(stim_type_vec), length(my_chans),'single');

%% Begin searching through datasets
% By individual files
for iname = 1:size(grand_ex_save,1)
    tic()
    fprintf('%d\n', iname)
    % Load in vars necessary for processing data
    latency_samples = grand_ex_save{iname,isubj}.info.recording.latency_samples;
    stimulus = grand_ex_save{iname,isubj}.info.stimulus.waveform;
    fs = grand_ex_save{iname,isubj}.info.recording.sampling_rate_hz;
    ramp_duration_samples = grand_ex_save{iname,isubj}.info.stimulus.ramp_duration_ms/1e3*fs;
    target_freq = grand_ex_save{iname,isubj}.info.stimulus.frequency_hz*2;
    trim_stim_pre_dur_ms = grand_ex_save{iname,isubj}.info.stimulus.trim_stim_pre_dur_ms;

    % Get number of batches
    n_batches = size(grand_ex_save{iname,isubj}.raw_signals,2);

    % Get a vector of the number of times collection was attempted
    collect_attempt_vec = cat(1,grand_ex_save{iname,isubj}.block_level_info(1:n_batches).collection_attempts);
    collect_attempt_vec = [collect_attempt_vec ; 0]; % To account for times where the very last batch was a retry and had enough trials by then, but there are no batches after so there won't be a negative value
    att_diff = diff(collect_attempt_vec);
    last_batch_loc = find(att_diff < 0);
    first_batch_loc = last_batch_loc + att_diff(last_batch_loc); % By adding the neg diff value onto its own index, we can find the idx value of the first associated batch
    mult_batch_locs = [first_batch_loc last_batch_loc]; % Matrix showing first batch and corresponding last batch
    single_batch_locs = setdiff(1:n_batches, mult_batch_locs)'; % These batches contain all trials needed

    %% Begin compiling raw time vector data
    % Search by channels
    for ichan = 1:length(my_chans)
        cur_chan = my_chans(ichan);
        row_idx = 1; % Reset after every channel
        for ibatch = 1:n_batches

            % Get kept_trials for each set of iblocks
            [kept_trials, kept_jitter, kept_phase] = get_kept_trials(grand_ex_save, iname, isubj, ...
                ibatch, cur_chan, single_batch_locs, mult_batch_locs);

            if ~isempty(kept_trials)
                %% Calculate fft and find 2f bin
                % Preallocate
                n_trials = size(kept_trials,1);
                temp_ON_2f = NaN(n_trials,1);
                temp_OFF_2f = NaN(n_trials,1);

                % Get indices for populating matrices
                amp_idx = find(amp_vec == round(grand_ex_save{iname,isubj}.block_level_info(ibatch).stim_amp)); % Round for sensitive doubles
                stim_type_idx = find(strcmp(stim_type_vec, ...
                    grand_ex_save{iname,isubj}.block_level_info(ibatch).stim_type));

                if isempty(amp_idx) || isempty(stim_type_idx)
                    keyboard
                end
                
                % Find the first full NaN row to start populating from
                start_row = find(isnan(ON_2f(:,amp_idx,stim_type_idx,ichan)), 1, 'first');
                row_range = start_row:start_row+n_trials-1;

                % Extract ON/OFF periods
                cur_stim_type = grand_ex_save{iname,isubj}.block_level_info(ibatch).stim_type;
                if strcmp(cur_stim_type, 'trim')
                    [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
                        kept_trials, 0, fs, ...
                        latency_samples, length(stimulus), ramp_duration_samples,...
                        trim_stim_pre_dur_ms,...
                        kept_jitter);
                else % It is ONOFF
                    [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
                        kept_trials, 1, fs, ...
                        latency_samples, length(stimulus), ramp_duration_samples,...
                        [],...
                        kept_jitter);
                end

                % Make sure to keep phase_vec info
                phase_vec(row_range, 1, amp_idx, stim_type_idx, ichan) = kept_phase'; 

                % Loop through stim_ON/stim_OFF
                for itrial = 1:n_trials
                    % Stim ON
                    cur_trial = stim_ON(itrial,:);
                    cur_trial(isnan(cur_trial)) = [];
                    [~, tmp_freq_vec, tmp_fft_vals] = calc_fft(cur_trial, fs);
                    [temp_ON_2f(itrial), target_bin_loc] = ...
                        find_fft_bins(target_freq, target_freq_range, tmp_fft_vals, tmp_freq_vec);

                    % Save to mega fft structure for waterfall
                    freq_vec_range = find(tmp_freq_vec >=low_lim & tmp_freq_vec <= up_lim);
                    select_freq_vec = tmp_freq_vec(freq_vec_range);
                    select_fft_vals = tmp_fft_vals(freq_vec_range);
                    freq_vec(row_range(itrial), 1:size(select_fft_vals,2), amp_idx, stim_type_idx, ichan) = select_freq_vec;
                    ON_fft_vals(row_range(itrial), 1:size(select_fft_vals,2), amp_idx, stim_type_idx, ichan) = select_fft_vals;
                    
                    % Stim OFF for ONOFF Stim types
                    if strcmp(cur_stim_type, 'ONOFF')
                    cur_trial_OFF = stim_OFF(itrial,:);
                    cur_trial_OFF(isnan(cur_trial_OFF)) = [];
                    
                    [~, tmp_freq_vec, tmp_fft_vals] = calc_fft(cur_trial_OFF, fs);
                    freq_vec_range = find(tmp_freq_vec >=low_lim & tmp_freq_vec <= up_lim);
                    select_freq_vec_OFF = tmp_freq_vec(freq_vec_range);
                    
                    % Check for any size mismatches between ON OFF periods,
                    % there should not be
                    if any(size(cur_trial) ~= size(cur_trial_OFF)) || ...
                            any(select_freq_vec_OFF ~= select_freq_vec)
                        keyboard
                    end
                    
                    OFF_fft_vals(row_range(itrial),1:size(select_fft_vals,2),amp_idx,1,ichan) = ...
                        tmp_fft_vals(freq_vec_range);
                    [temp_OFF_2f(itrial), target_bin_loc] = ...
                        find_fft_bins(target_freq, target_freq_range, tmp_fft_vals, tmp_freq_vec);
                    end
                end

                %% Populate ON_2f and OFF_2f bin magnitude matrices
                % Populate
                if any(isnan(temp_ON_2f)) || (any(isnan(temp_OFF_2f)) & strcmp(cur_stim_type, 'ONOFF'))
                    keyboard
                end
                
                ON_2f(row_range,amp_idx,stim_type_idx,ichan) ...
                    = temp_ON_2f;

                if strcmp(cur_stim_type, 'ONOFF')
                    OFF_2f(row_range,amp_idx,1,ichan) ...
                        = temp_OFF_2f;
                end
            end


        end
    end
    toc()
end

dbstop = 1;