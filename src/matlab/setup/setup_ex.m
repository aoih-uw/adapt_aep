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
ex.no_valid_trials = 0;

% Trial counter
for iamp = 1:100
    ex.trial_count(iamp) = 0;
    ex.valid_trials(iamp) = NaN;
    ex.rejected_trials{iamp} = NaN;
    ex.decision(iamp).resp_found = 0; 
    ex.decision(iamp).current_amplitude = NaN; %# have this assigned when resp_found is assigned as well in separate, subtract, bootstrap etc. etc.!
    ex.decision(iamp).amp_done = 0;
    ex.decision(iamp).amp_done_reason = NaN;
end

% Setup health
ex = setup_health(ex);
end