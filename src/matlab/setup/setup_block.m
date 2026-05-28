function ex = setup_block(ex)
%% Setup block-level layers to ex

%% Per block metadata
max_block = ceil(ex.info.adaptive.max_trials / ex.info.adaptive.trials_per_block);

%% Trial counter
for iblock = 1:max_block
% use iblocks but you can get all data easily using all_num_blocks = [ex.block.num_blocks]  % Easy extraction
ex.block(iblock).water_temp_C = NaN; % Get thermometer working
ex.block(iblock).jitter = NaN;
ex.block(iblock).phase_vec = NaN;
ex.block(iblock).stimulus_block = NaN; % Created in make_scaled_jittered_stim_block, presented via playrec
ex.block(iblock).hydrophone.stim_ON_rms_dB_spl = NaN;
ex.block(iblock).hydrophone.stim_OFF_rms_dB_spl = NaN;

%% Raw data
ex.raw(iblock).hydrophone_mV= NaN;
ex.raw(iblock).electrodes_microV = NaN; % order follows ex.info.channels.names
ex.raw(iblock).time_stamp = NaN;
ex.raw(iblock).loopback = NaN;

% Preprocessing
ex.preprocess(iblock).rel_reject_threshold = [];
ex.preprocess(iblock).reject_rate =  [];
ex.preprocess(iblock).channel_weights = [];

end

% Setup noise
ex.noise.starting_rms = NaN;