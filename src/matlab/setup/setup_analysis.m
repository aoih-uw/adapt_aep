function ex = setup_analysis(ex)
%% Setup analysis level fields to ex, kept and model 
% Kept trials
ex.kept.trials = [];
ex.kept.phases = [];
ex.kept.jitter = [];
ex.kept.channels = [];
ex.kept.trials_weighted = [];
ex.kept.trials_filtered = [];

% FFT structure
ex.fft.diffs = [];
ex.fft.stim_ON = [];
ex.fft.stim_OFF = [];
ex.fft.freq_vec = [];
ex.fft.stim_ON_2f_vec = [];
ex.fft.stim_OFF_2f_vec = [];
ex.fft.diff_2f_vec = [];

% Bootstrap Test
for iboot = 1:100
ex.stats(iboot).gate_type = [];
ex.stats(iboot).bootstat = [];
ex.stats(iboot).lower_CI = [];
ex.stats(iboot).upper_CI = [];
ex.stats(iboot).perm_test_stat = [];
ex.stats(iboot).perm_sig_threshold = [];
ex.stats(iboot).perm_test_result = [];
end


