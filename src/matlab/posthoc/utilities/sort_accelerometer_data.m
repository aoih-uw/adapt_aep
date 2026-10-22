%% sort_accelerometer_data
%% Unpack variables
latency = grand_ex_save{1,1}.info.DAC.latency_samples;
fs = grand_ex_save{1,1}.info.DAC.sampling_rate_hz;
microphone_mV_per_Pa = grand_ex_save{1,1}.info.hydrophone.gain_mV_per_Pa;

% Accelerometer
mV_per_m_per_s_sqrd = grand_ex_save{1,1}.info.accel.mV_per_m_per_s_sqrd;

stim_freqs = grand_ex_save{1,1}.info.mixed.stim_freqs;
stim_amps = grand_ex_save{1,1}.info.mixed.test_amplitudes;
my_chans = grand_ex_save{1,1}.info.DAC.input_channel_names(ismember(grand_ex_save{1,1}.info.DAC.input_channel_names,{'X', 'Y','Z'}));

% Impedance reference
Rayl_ref = 1.5597*1e6; % MRayl*1e6 = Rayl
RMS_P2P_factor = 20*log10(2*sqrt(2)); % dB RMS is ~9 dB lower than dB P2P

% Identify largest amp_vec for preallocation
[~, idx] = max(cellfun(@numel, stim_amps));
largest_amp_vec = stim_amps{idx};

%% Preallocate
max_trials = 260;
trials_per_block = 10;

% FFT
ON_fft = NaN(max_trials,4411,numel(stim_freqs),numel(largest_amp_vec),numel(my_chans));
OFF_fft = NaN(max_trials,4411,numel(stim_freqs),numel(largest_amp_vec),numel(my_chans));

% Time domain accel signals
stim_ON_m_per_s_sqrd = NaN(max_trials,8820,numel(stim_freqs),numel(largest_amp_vec),numel(my_chans));
stim_OFF_m_per_s_sqrd = NaN(max_trials,8820,numel(stim_freqs),numel(largest_amp_vec),numel(my_chans));

% dB
hydro_Pa_RMS = NaN(max_trials, numel(stim_freqs));
hydro_Pa_p2p = NaN(max_trials, numel(stim_freqs));
hydro_dB = NaN(max_trials, numel(stim_freqs));
accel_dB_all = NaN(max_trials, numel(stim_freqs), numel(largest_amp_vec));
accel_dB_per_dim = NaN(max_trials, numel(stim_freqs), numel(largest_amp_vec), numel(my_chans));

% Setup indexing
row_idx = ones(numel(stim_freqs), numel(largest_amp_vec));

% Exemplar: Time domain signal
exemplar_accel_sigs = NaN(max_trials,53000,numel(stim_freqs),numel(my_chans));
exemplar_hydro_sigs = NaN(max_trials,53000,numel(stim_freqs));

% Impedance values
imp_RMS = NaN(max_trials,numel(stim_freqs));
imp_p2p = NaN(max_trials,numel(stim_freqs));

%% Sort signals
for iname = 1:size(grand_ex_save,2)
    fprintf('File %d\n',iname)
    cur_file = grand_ex_save{1,iname};
    for iblock = 1:size(cur_file.raw_signals,2)
        cur_block = cur_file.raw_signals(iblock).accelerometer_mV;
        cur_hydro = cur_file.raw_signals(iblock).hydrophone_mV;
        cur_phase = cur_file.block_level_info(iblock).phase_vec;
        cur_jitter = cur_file.block_level_info(iblock).jitter;

        % Get current freq/amp locations
        freq_idx = find(cur_file.block_level_info(iblock).stim_freq == stim_freqs);
        amp_idx = find(cur_file.block_level_info(iblock).stim_amp == largest_amp_vec);

        % Get current rows
        n_trials = size(cur_block,1);
        cur_rows = row_idx(freq_idx,amp_idx) : row_idx(freq_idx,amp_idx) + n_trials - 1;
        % Make sure we have enough space in the preallocation
        assert(cur_rows(end) <= max_trials, 'Exceeded max_trials')
        
        % Get ON/OFF slicing info
        full_amp_on_samp = numel(cur_file.info.stimulus(1,freq_idx).waveform);
        ramp_duration_samples = (cur_file.info.stimulus(1,freq_idx).ramp_duration_ms/1000)*fs;
        amp_vec = stim_amps{freq_idx};

        for ichan = 1:numel(my_chans)
            cur_sigs = cur_block(:,:,ichan);

            % Save time domain signals at highest stimulus amplitude
            if largest_amp_vec(amp_idx) == max(largest_amp_vec)
                exemplar_accel_sigs(cur_rows,1:size(cur_sigs,2),freq_idx,ichan) = cur_sigs;

                % Save hydrophone signal once
                if ichan == numel(my_chans)
                    tmp_hydro = cur_hydro(:,:);
                    exemplar_hydro_sigs(cur_rows,1:size(tmp_hydro,2),freq_idx) = tmp_hydro;

                    % Calculate Hydrophone dB SPL
                    [stim_ON , ~] = extract_stim_ON_OFF( ...
                        tmp_hydro, 1, fs, latency, full_amp_on_samp, ...
                        ramp_duration_samples,[], cur_jitter);

                    cur_Pa = rms(stim_ON./microphone_mV_per_Pa,2); % Stim_ON is in mV
                    hydro_Pa_RMS(cur_rows,freq_idx) = cur_Pa;
                    hydro_dB(cur_rows,freq_idx) = 20*log10(cur_Pa/1e-6);
                    hydro_Pa_p2p(cur_rows,freq_idx) = peak2peak(stim_ON./microphone_mV_per_Pa,2);
                end
            end

            %% Separate ON/OFF periods
            [stim_ON , stim_OFF] = extract_stim_ON_OFF( ...
                cur_sigs, 1, fs, latency, full_amp_on_samp, ...
                ramp_duration_samples,[], cur_jitter);

            %% Calculate acceleration of stim ON
            stim_ON_m_per_s_sqrd(cur_rows,:,freq_idx,amp_idx,ichan) = stim_ON./mV_per_m_per_s_sqrd(ichan);
            stim_OFF_m_per_s_sqrd(cur_rows,:,freq_idx,amp_idx,ichan) = stim_OFF./mV_per_m_per_s_sqrd(ichan);

            %% Calculate Impedance for highest tested amplitude
            if largest_amp_vec(amp_idx) == max(largest_amp_vec) && ichan == numel(my_chans)
                % Pk-PK RMS Conversion
                cur_set = squeeze(stim_ON_m_per_s_sqrd(cur_rows,:,freq_idx,amp_idx,:)); % 10 x 8820

                % Calculate total acceleration across all dimensions
                tmp = vecnorm(cur_set,2,3);

                % Apply filter to signal to remove transients
                filt_tmp = medfilt1(tmp, 15,[],2);

                % Calculate acceleration magnitude
                accel_rms = rms(filt_tmp,2);
                accel_p2p = 2*max(filt_tmp,[],2); % Multiply the peak*2 since the signal got rectified, so its not possible to do a pk-pk measure

                % Calculate ratio
                f = stim_freqs(freq_idx);
                imp_RMS(cur_rows,freq_idx) = 20*log10(((hydro_Pa_RMS(cur_rows,freq_idx))./(accel_rms/(2*pi*f)))./Rayl_ref);
                imp_p2p(cur_rows,freq_idx) = 20*log10(((hydro_Pa_p2p(cur_rows,freq_idx))./(accel_p2p/(2*pi*f)))./Rayl_ref);

            end

            %% Calculate complex fft per trial
            % FFT values reflect m/s^2 acceleration not mV
            for itrial = 1:size(stim_ON_m_per_s_sqrd(cur_rows,:,freq_idx,amp_idx,ichan),1)
                [tmp_freq_vec, tmp_ON] = calc_fft_complex(stim_ON_m_per_s_sqrd(cur_rows(itrial),:,freq_idx,amp_idx,ichan), fs);
                [~, tmp_OFF] = calc_fft_complex(stim_OFF_m_per_s_sqrd(cur_rows(itrial),:,freq_idx,amp_idx,ichan), fs);
                ON_fft(cur_rows(itrial),1:length(tmp_ON),freq_idx,amp_idx,ichan) = tmp_ON;
                OFF_fft(cur_rows(itrial),1:length(tmp_OFF),freq_idx,amp_idx,ichan) = tmp_OFF;
            end
        end

        %% Calculate dB RMS %#% CHECK CODE
        my_ON = reshape(stim_ON_m_per_s_sqrd(cur_rows,:,freq_idx,amp_idx,:), ...
            n_trials, [], numel(my_chans));
        accel_dB_per_dim(cur_rows,freq_idx,amp_idx,:) = 20*log10(rms(my_ON,2)/1e-6);
        accel_dB_all(cur_rows,freq_idx,amp_idx) = 20*log10(rms(vecnorm(my_ON,2,3),2)/1e-6);

        %% Progress counter
        row_idx(freq_idx,amp_idx) = row_idx(freq_idx,amp_idx) + n_trials;
    end
end

