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

%% Iteration Counters
ex.counter.iamp = 0;
ex.counter.iblock = 0;
ex.counter.health = 0;

% Experiment done marker
ex.exp_done = 0;

% Set up sets of ex
ex = setup_info(ex); % User input of experiment parameters
ex = setup_block(ex); % Per amplitude meta/data
ex = setup_analysis(ex); % Analysis deta/data
end