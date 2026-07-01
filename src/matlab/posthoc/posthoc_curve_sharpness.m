cur_name = 14;
my_names{1,1}{cur_name};
cur_data = grand_ex_save{cur_name,1};
my_channels = [2 3 4];
N_batches = size(cur_data.raw_signals, 2);
latency_samp = cur_data.info.recording.latency_samples; % Latency samples not down sampled
stimulus = cur_data.info.stimulus.waveform;
fs = cur_data.ds_fs;
ds_rate = 2;
for ibatch = 1:N_batches
    for itrial = 1:10
        for ichan = 1:length(my_channels)
            cur_chan = my_channels(ichan);
            g_trial_count = (ibatch-1)*10+itrial;
            if ~ismember(g_trial_count,cur_data.rejected_trials{:})
                cur_jitter = cur_data.block_level_info(1).jitter(itrial);
                stim_start = cur_jitter/ds_rate + latency_samp/ds_rate + (5/1e3*fs); % 5 ms off period;
                stim_end = stim_start + length(stimulus)/ds_rate -1;
                % Trim recording to only include when the response is on
                cur_resp = cur_data.raw_signals(ibatch).electrodes_microV_ds(itrial,stim_start:stim_end,cur_chan);
            end
        end
    end
end