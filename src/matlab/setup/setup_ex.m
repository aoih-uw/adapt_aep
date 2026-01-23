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

%% Per block metadata
% use iblocks but you can get all data easily using all_num_blocks = [ex.block.num_blocks]  % Easy extraction
ex.block(1).water_temp_C = NaN; % Get thermometer working
ex.block(1).jitter = NaN;
ex.block(1).stimulus_block = NaN;
ex.block(1).num_rejected = NaN;
ex.block(1).reject_rate = NaN;

%% Raw data
ex.raw(1).hydrophone = NaN; % Only keep RMS? or the mean across each block?
ex.raw(1).electrodes = NaN; % order follows ex.info.channels.names
ex.raw(1).time_stamp = datetime('now');

%% Cleaned data
ex.cleaned(1).electrodes = NaN;

%% Decision
ex.decision(1).resp_found = 0;
ex.decision(1).amp_done = 0;
ex.decision(1).amp_done_reason = NaN;
ex.decision.exp_done = 0;
ex.decision.exp_done_reason = NaN;
ex.decision.threshold_spl = NaN;

%% Counter
ex.counter.iamp = 0;
ex.counter.iblock = 0;
ex.counter.health = 0;

%% Analysis
ex.analysis(1).doub_freq_mag_mean = NaN; % save by block
ex.analysis(1).doub_freq_mag_std= NaN;

%% Health
ex.health.stim_frequency_hz = 100; %# User needs to set this too...
ex.health.stim_amp_spl = 140; %# User needs to set this too...
ex.health(1).time_stamp = datetime('now');
ex.health.waveforms = NaN;
ex.health(1).doub_stim_mag = NaN;
ex.health(1).status = NaN;
ex.health(1).end_test = 0;

%% Create sound stimulus template
ex = make_tone_burst_template(ex);
ex = make_health_check_signal(ex);
end