function ex = setup_ex
ex = struct( ...
    'params', struct(), ...     % static experiment configuration
    'trial', struct(), ...      % per-trial metadata (transient)
    'raw', struct(), ...   % raw signals
    'analysis', struct() ...    % derived metrics
);

ex = setup_params(ex);
ex = setup_trial(ex);
ex = setup_raw(ex); % electrode, hydrophone, timestamps
ex = setup_analysis(ex);
end