function ex = setup_ex()
%% put this in the GUI code first actually
ex = struct( ...
    'info', struct(), ...     % static experiment configuration
    'block', struct(), ...      % per-trial metadata (transient)
    'raw', struct(), ...   % raw signals
    'cleaned', struct(), ...  % cleaned signals
    'analysis', struct(), ...    % derived metrics
    'model', struct(), ...
    'decision', struct(), ...
    'counter', struct(), ...
    'health', struct() ...
);

ex = setup_info(ex);

%% Iteration Counters
ex.counter.iamp = 0;
ex.counter.iblock = 0;
ex.counter.health = 0;

%% Trial counter
ex.trial_count(1) = NaN;
ex.trial_count(1) = [];

% Experiment done marker
ex.exp_done = 0;

%% Per block metadata
% use iblocks but you can get all data easily using all_num_blocks = [ex.block.num_blocks]  % Easy extraction
ex.block(1).water_temp_C = NaN; % Get thermometer working
ex.block(1).jitter = NaN;
ex.block(1).phase_vec = NaN;
ex.block(1).stimulus_block = NaN; % Created in make_stim_block, presented via playrec
ex.block(1).N_trials_presented = NaN;

%% Raw data
ex.raw(1).hydrophone = NaN;
ex.raw(1).electrodes = NaN; % order follows ex.info.channels.names
ex.raw(1).time_stamp = NaN;

%% Health
ex.health(1).time_stamp = NaN;
ex.health(1).doub_stim_mag = NaN;
ex.health(1).status = NaN;
ex.health(1).end_test = 0;

%% Decision
ex.decision(1).resp_found = 0;
ex.decision(1).current_amplitude = NaN; %# have this assigned when resp_found is assigned as well in separate, subtract, bootstrap etc. etc.!
ex.decision(1).amp_done = 0;
ex.decision(1).amp_done_reason = NaN;

% Preprocessing
ex.preprocess(1).rel_reject_threshold = [];
ex.preprocess(1).total_trials_presented =  0;
ex.preprocess(1).N_trials_presented = [];
ex.preprocess(1).reject_rate =  [];

% Kept trials
ex.kept.trials = [];
ex.kept.phases = [];
ex.kept.jitter = [];
ex.kept.channels = [];
ex.kept.trials_weighted = [];
ex.kept.trials_filtered = [];

% Model
ex.model.doub_freq_resp_vec_mV = []; % Delete from ex when saving
ex.model.noise_floor = []; % Delete from ex when saving

ex.model.response_mean = [];
ex.model.response_vars = [];

ex.model.noise_floor_mean = [];
ex.model.noise_floor_std = [];

ex.model.amplitude_vec = [];
ex.model.x0_fit = [];
ex.model.a1_fit = [];
ex.model.m_fit = [];
ex.model.y_int = [];

%% Create sound stimulus template
ex = make_tone_burst_template(ex);
ex = make_health_check_signal(ex);

end