function freq_idx = get_current_freq_idx(ex)
% Get current frequency idx
switch ex.info.experiment.exp_type
    case 'Mixed freqs'
        test_schedule = ex.info.mixed.test_schedule;
        ischedule = ex.counter.ischedule;
        cur_parameters = test_schedule(ischedule,:); % [stim_freq, stim_name, stim_amp, trials_needed, uniq_idx]
        stim_freq = cur_parameters(1);
        freq_idx = find(ex.info.mixed.stim_freqs == stim_freq);
    otherwise
        freq_idx = 1;
end