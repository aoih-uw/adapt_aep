function ex = setup_ex()
%% put this in the GUI code first actually
ex = struct( ...
    'info', struct(), ...     % static experiment configuration
    'block', struct(), ...      % per-trial metadata (transient)
    'raw', struct(), ...   % raw signals
    'cleaned', struct(), ...  % cleaned signals
    'periods', struct(), ...    % derived metrics
    'bootstrap', struct(), ...    % derived metrics
    'model', struct(), ...
    'decision', struct() ...
);

ex = setup_info(ex);
ex.next_amplitude = NaN; % Will be assigned a value in select_next_GUI

%% Per block metadata
% use iblocks but you can get all data easily using all_num_blocks = [ex.block.num_blocks]  % Easy extraction
ex.block(1).iteration_num = NaN;
ex.block(1).water_temp_C = NaN; % Get thermometer working
ex.block(1).jitter = NaN;
ex.block(1).stimulus_block = NaN;

%% Raw data
N_channels = ex.info.channels.N_channels;
ex.raw(1).hydrophone = NaN; % Only keep RMS? or the mean across each block?
ex.raw(1).electrodes = NaN; % order follows ex.info.channels.names
ex.raw(1).time_stamp = NaN;

%% Cleaned data
ex.cleaned(1).electrodes = NaN;

%% Model data
ex.model(1).x_vector = [];
ex.model(1).y_vector = [];
ex.model(1).fit_x0 = NaN;
ex.model(1).fit_kappa = NaN;
ex.model(1).fit_lmbda = NaN;
ex.model(1).fit_max_resp = NaN;

end