%% make_simulated_aep
% Setup variables
% signal_scale = linspace(0,0.05,16);
signal_scale = linspace(0,1,16);
n_trials = 1030;
trials_per_block = 10;
noise_idx = 1; % Counter for which stim_OFF/noise trial we have used

% Initalize ex structure for simulation
app.DropDown_test_mode.Value = 'Mixed freqs';
app.DropDown_test_tag.Value = 'mixed_freqs';
ex = setup_ex(app);
ex = setup_info(ex,app);
fs = ex.info.DAC.sampling_rate_hz;
ex.info.experiment.exp_type = 'Mixed freqs';
ex.info.DAC.latency_samples = 2118;
app.DropDown_tone_burst.Value = 'Tone Burst';
%% Set Stimulus Frequency and amplitude from this point
ex = setup_stimulus_info(ex,app);

% Preallocate
snr_mat = NaN(length(ex.info.mixed.stim_freqs),length(signal_scale),n_trials/trials_per_block);
n_samp = 60000;  % or the actual length(sig_block)
simulated_aep = NaN(trials_per_block, n_samp, length(ex.info.mixed.stim_freqs), ...
    length(signal_scale), n_trials/trials_per_block, 'single');
phase_mat = NaN(trials_per_block, 1, length(ex.info.mixed.stim_freqs), ...
    length(signal_scale), n_trials/trials_per_block, 'single');
jitter_mat = NaN(trials_per_block, 1, length(ex.info.mixed.stim_freqs), ...
    length(signal_scale), n_trials/trials_per_block, 'single');

% Setup stimulus parameters based on 1f
for ifreq = 1:size(ex.info.stimulus,2)
    stim_freq = ex.info.stimulus(ifreq).frequency_hz;
    period_s = 1/stim_freq;
    period_samps = period_s*fs;
    ramp_cycles = ex.info.stimulus(ifreq).ramp_duration_cycles;
    desired_freq_res = ex.info.stimulus(ifreq).desired_freq_res;
    % Select durations of full amp and ramp portions
    [full_amp_duration_ms, ramp_duration_ms]= select_experiment_stim_params(fs, stim_freq, period_s, period_samps, ramp_cycles, desired_freq_res);
    ex.info.stimulus(ifreq).full_amplitude_duration_ms = full_amp_duration_ms;
    ex.info.stimulus(ifreq).ramp_duration_ms = ramp_duration_ms;
    % Make stimulus template but here now set stimulus freq to 2f so that the
    % actual stim ON waveform is at 2f
    [tone_burst, total_sig_duration] = make_stimulus_template(fs, stim_freq*2,full_amp_duration_ms,ramp_duration_ms);
    ex.info.stimulus(ifreq).total_stimulus_duration_ms = total_sig_duration;
    ex.info.stimulus(ifreq).waveform = tone_burst;
end

%% Add noise to signal
for ifreq = 1:size(ex.info.stimulus,2)
    for iamp = 1:length(signal_scale)
        cur_scale_fac = signal_scale(iamp);
        for ibatch = 1:(n_trials/trials_per_block)
            waveform = ex.info.stimulus(1,ifreq).waveform;
            
            % Set target RMS for noise so it matches original waveform rms
            % We only want to scale the waveform, so when waveform scaling
            % = 1, then it is the same rms amplitude as the noise
            target_rms = rms(waveform);
            cur_freq = ex.info.stimulus(1,ifreq).frequency_hz;
            
            % Make faux signal, ON/OFF periods, just like
            % in the live experiment
            % 170 dB set as target level to get a tone burst with pk-pk = 2
            % digital to make scaling easy
            [ex, selected_cycle_samples, sig_block, phase_vec] = ...
                make_scaled_jittered_stim_block(ex, waveform, 170, trials_per_block, ...
                [], 1, cur_freq, 1);
            
            % Store variables
            ex.block(ibatch).jitter = selected_cycle_samples;
            ex.block(ibatch).phase_vec = phase_vec.*phase_vec;
            
            % Simulate playrec by scaling and adding noise to signal
            % Scale signal
            scaled_sig_block = sig_block.*cur_scale_fac;

            % Reverse balanced phases!
            scaled_sig_block = scaled_sig_block.*phase_vec;
            
            % Generate noise block
            % Need to stitch together 6 stim_OFF trials to get enough
            % samples to add scaled_sig_block with
            target_sample_length = size(scaled_sig_block,2);
            n_trials_needed = ceil(target_sample_length/size(noise_data,2));
            stitch_noise_block = NaN(trials_per_block,target_sample_length);
            
            % Build trial by trial
            for itrial = 1:size(scaled_sig_block,1)
                % Wrap around using same trials
                cur_set = mod(noise_idx-1 : noise_idx+n_trials_needed-2, size(noise_data,1)) + 1;
                noise_block = noise_data(cur_set,:);

                % Get the batch of individual stim_OFF trials needed to
                % stitch
                for inoise = 1:size(noise_block,1)
                    cur_noise = noise_block(inoise,:);
                    % Apply scaling to noise

                    noise_rms = rms(cur_noise);
                    noise_scaling_fac = (target_rms/noise_rms);

                    % Set noise RMS to the original waveform pk to pk 1 value
                    cur_noise = cur_noise.*noise_scaling_fac;
                    noise_block(inoise,:) = cur_noise;
                end

                % Stitch together
                stitched_noise = reshape(noise_block.',1,[]);
                stitch_noise_block(itrial,:) = stitched_noise(1,1:target_sample_length);
                % Increment counter
                noise_idx = noise_idx+n_trials_needed;
            end

            % Calculate current SNR
            noise_rms = rms(stitch_noise_block,2);
            % Base signal snr on the full amplitude pk-pk 2 waveform being scaled down
            snr_mat(ifreq,iamp,ibatch) =  rms(waveform.*cur_scale_fac)/mean(noise_rms);
            simulated_aep(:, 1:size(scaled_sig_block,2), ifreq, iamp, ibatch) = scaled_sig_block + stitch_noise_block;
            phase_mat(:,1,ifreq,iamp,ibatch) = phase_vec;
            jitter_mat(:,1,ifreq,iamp,ibatch) = selected_cycle_samples;
        end
    end
end
% For future plotting
snr_vec = snr_mat(1,:,1);
% Save
% save("simulated_aep.mat","simulated_aep","snr_mat","phase_mat","jitter_mat","signal_scale","n_trials","trials_per_block",'-v7.3')