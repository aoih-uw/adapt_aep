function ex = setup_ex()
%% put this in the GUI code first actually
ex = struct( ...
    'info', struct(), ...     % static experiment configuration
    'block', struct(), ...      % per-trial metadata (transient)
    'raw', struct(), ...   % raw signals
    'model', struct(), ...
    'decision', struct(), ...
    'counter', struct(), ...
    'health', struct() ...
    );

%% Iteration Counters
ex.counter.iamp = 0;
ex.counter.iblock = 0;
ex.counter.ihealth = 0;
ex.counter.iboot = 0;

% Experiment State Markers
ex.exp_done = 0;
ex.test = 0;
ex.last_autosave_time = [];

% Trial counter
for iamp = 1:100
    ex.trial_count(iamp) = 0;
    ex.decision(iamp).resp_found = 0; 
    ex.decision(iamp).current_amplitude = NaN; %# have this assigned when resp_found is assigned as well in separate, subtract, bootstrap etc. etc.!
    ex.decision(iamp).amp_done = 0;
    ex.decision(iamp).amp_done_reason = NaN;
end

% Set up sets of ex
ex = setup_info(ex); % User input of experiment parameters
ex = setup_block(ex); % Per amplitude meta/data
ex = setup_analysis(ex); % Analysis deta/data
ex = setup_model(ex);

% Setup health
for ihealth = 1:100
    ex.health(ihealth).hydrophone_mV= NaN;
    ex.health(ihealth).electrodes_microV= NaN;
    ex.health(ihealth).time_stamp = NaN;
    ex.health(ihealth).doub_stim_mag = NaN;
    ex.health(ihealth).rel_strength = NaN;
    ex.health(ihealth).status = NaN;
    ex.health(ihealth).end_test = 0;
end

end