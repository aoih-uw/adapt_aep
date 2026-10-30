%% posthoc_bootstrap_simulation
%% Assign variables
% Metadata
subjid = meta.subjid;
amp_vecs = meta.amp_vecs;
stim_type_vec = meta.stim_type_vec;
if isfield(meta, 'stim_freqs')
    stim_freqs = meta.stim_freqs;
else
    stim_freqs = meta.stim_freq;
end
my_chans = meta.my_chans;
my_chans_name = meta.my_chans_name;
target_freq_range = meta.target_freq_range;
trials_per_block = meta.trials_per_block;
max_trials = meta.ON_OFF_max_trials;
use_sigmoid = 0;
plot_linear = 0;

% Number of reliability/robustness runs
n_boot = 5000;

% Organized data
ON_2f        = org_data.ON_2f;
OFF_2f       = org_data.OFF_2f;
OFF_fft = org_data.OFF_fft;
phase_vec    = org_data.phase_vec;

% Function specific vars
stim_type_idx = find(strcmp('ONOFF',stim_type_vec));
max_batches = max_trials/trials_per_block; % e.g. 130 trials in batches of 10
twof_growth = [];

%% Set pre-alpha value 
% pre_alpha: before adding correction for multiple comparisons
pre_alpha = 0.05;
my_alpha = pre_alpha/max_batches; % Each batch you take one peek...

% Clear vars
clear sim_results fit_quality_2f fit_quality_low fit_quality_F

% Loop through first by frequency
for ifreq = 1:length(stim_freqs)
    %% Assign frequency specific variables
    tic()
    field_name = sprintf('c%d',ifreq);
    cur_freq = stim_freqs(ifreq);
    fprintf('Processing %d Hz...', cur_freq);
    
    % Assign current frequency amp_vec
    amp_vec = amp_vecs{ifreq};

    % Cumulative trial averaging matrix
    sz = [max_batches, length(amp_vec), length(my_chans), n_boot];
    cumu.n                       = NaN(sz);
    cumu.diff.mean.twof            = NaN(sz); % Mean 2f microvolt amplitude for each cumulative average by 10 trials for each batch and channel and stim amplitude
    cumu.diff.sem.twof             =  NaN(sz); 
    cumu.noise_floor.mean.twof     = NaN(sz); 
    cumu.noise_floor.sem.twof     =  NaN(sz);
    cumu.F_stats                = NaN([max_batches, 2, length(amp_vec), length(my_chans)]);

    % Set to empty
    all_data = []; ds_data = []; bottom_up = []; top_down = [];

    % Package my_params
    my_params.my_chans         = my_chans;
    my_params.my_chans_name    = my_chans_name;
    my_params.amp_vec          = amp_vec;
    my_params.phase_vec        = phase_vec;
    my_params.ON_2f            = ON_2f;
    my_params.OFF_2f           = OFF_2f;
    my_params.stim_type_idx    = stim_type_idx;
    my_params.ifreq            = ifreq;
    my_params.cur_freq          = stim_freqs(ifreq);
    my_params.max_batches      = max_batches;
    my_params.trials_per_block = trials_per_block;
    my_params.my_alpha         = my_alpha; % Base alpha value divided by the number of looks you are going to take
    my_params.n_boot           = n_boot;
    %% Execute cumulative averaging/adaptive simulation
    [cumu, polar] = execute_cumu_avg_bootstrap(my_params, cumu);

    %% Simulate adaptive trial count
    % By n iteration
   F_count = sim_trial_count_heatmap(amp_vec, cumu,...
        max_trials, my_chans, my_chans_name, trials_per_block, my_params);
    
    %% Plot 2f growth functions
    [twof_growth, fit_quality_2f(ifreq)] = plot_2f_growth_func...
        (cumu, F_count.first, amp_vec, my_chans, my_chans_name, ...
        trials_per_block, stim_freqs(ifreq), use_sigmoid,plot_linear);

    %% Plot p value across amplitude
    [F_growth, fit_quality_F(ifreq)] = fit_F_stat_model(amp_vec, cumu, F_count.first, my_params, ifreq, ...
    trials_per_block, max_trials, my_chans_name, cur_freq, 'Full dataset', 1);

    %% Simulate removal of data points
    T_error = sim_data_removal(F_growth,amp_vec,my_params,cur_freq);

    %% Convert simulation results to long form table
    sim_results(ifreq) = convert_sim_data_to_long(subjid, cur_freq, amp_vec, ...
    F_count, twof_growth, F_growth, fit_quality_F(ifreq), my_chans, my_chans_name, cumu, polar);
    
    %% Report progress
    toc()
end