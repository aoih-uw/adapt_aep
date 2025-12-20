function ex = setup_ex()
%% put this in the GUI code first actually
ex = struct( ...
    'info', struct(), ...     % static experiment configuration
    'block', struct(), ...      % per-trial metadata (transient)
    'raw', struct(), ...   % raw signals
    'analysis', struct() ...    % derived metrics
);

ex = setup_info(ex);

%%
% ex = setup_block(ex);
ex.info.block(iblock).water_temp_C = NaN; % Get thermometer working
ex.info.block(iblock).jitter = jitter;

ex = setup_raw(ex); % electrode, hydrophone, timestamps
ex = setup_analysis(ex);
end