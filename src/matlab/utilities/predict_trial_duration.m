function predict_trial_duration
freqs_hz = [55 100 200 400 830 1000];
num_trials = [16 32 64 128 256 512 1024];
num_cycles = 6;
fs = 44100;

for itrial = 1:length(num_trials)
    for ifreq = 1:length(freqs_hz)
        cur_freq = freqs_hz(ifreq);
        ms_for_all_cycles = num_cycles*(1/cur_freq)*1e3;
        min_samp_needed = fs/5; % fs/desired freq resolution
        full_amp_ms = max(ms_for_all_cycles, min_samp_needed/fs*1e3);
        ramp_ms = max(50, ms_for_all_cycles);

        off_on_dur_ms = (full_amp_ms+ramp_ms*2)*2+(2118/fs*1e3); % 2118 = latency
        if cur_freq < 100
            post_stim_ms = 1000; % 1 sec pause
        elseif cur_freq >= 100 && cur_freq < 200
            post_stim_ms = 100; % 100 ms pause
        elseif cur_freq >= 200
            post_stim_ms = 50; % 50 ms pause
        end

        whole_trial_dur_sec(ifreq) = ((off_on_dur_ms + post_stim_ms)/1e3);
        whole_freq_test_dur_min(ifreq,itrial) = (whole_trial_dur_sec(ifreq)/60)*num_trials(itrial);
    end
end

db = 1;