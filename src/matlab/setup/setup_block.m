function ex = setup_block(ex)
%% Per block metadata
max_block = ex.info.adaptive.max_trials / ex.info.adaptive.trials_per_block;

%% Trial counter
for iblock = 1:max_block
% use iblocks but you can get all data easily using all_num_blocks = [ex.block.num_blocks]  % Easy extraction
ex.block(iblock).water_temp_C = NaN; % Get thermometer working
ex.block(iblock).jitter = NaN;
ex.block(iblock).phase_vec = NaN;
ex.block(iblock).stimulus_block = NaN; % Created in make_stim_block, presented via playrec

%% Raw data
ex.raw(iblock).hydrophone = NaN;
ex.raw(iblock).electrodes = NaN; % order follows ex.info.channels.names
ex.raw(iblock).time_stamp = NaN;

%% Health
ex.health(iblock).time_stamp = NaN;
ex.health(iblock).doub_stim_mag = NaN;
ex.health(iblock).status = NaN;
ex.health(iblock).end_test = 0;

% Preprocessing
ex.preprocess(iblock).rel_reject_threshold = [];
ex.preprocess(iblock).total_trials_presented =  0;
ex.preprocess(iblock).N_trials_presented = [];
ex.preprocess(iblock).reject_rate =  [];

end