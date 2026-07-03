function ex = setup_analysis(ex)
%% Setup analysis level fields to ex, kept and model 
% Kept trials
ex.kept.trials = [];
ex.kept.phases = [];
ex.kept.jitter = [];

if strcmp(ex.info.experiment.exp_type,'Adaptive')
% FFT structure
ex.fft.diffs = [];
ex.fft.stim_ON = [];
ex.fft.stim_OFF = [];
ex.fft.freq_vec = [];
ex.fft.stim_ON_2f_vec = [];
ex.fft.stim_OFF_2f_vec = [];
ex.fft.diff_2f_vec = [];

% Bootstrap Test
for iboot = 1:1000
ex.bootstrap(iboot).gate_type = [];
ex.bootstrap(iboot).bootstat = [];
ex.bootstrap(iboot).lower_CI = [];
ex.bootstrap(iboot).upper_CI = [];
ex.bootstrap(iboot).perm_test_stat = [];
ex.bootstrap(iboot).perm_sig_threshold = [];
ex.bootstrap(iboot).perm_test_result = [];
end
end
