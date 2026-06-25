function ex = setup_block(ex)
%% Setup block-level layers to ex

%% Per block metadata
if ~strcmp(ex.info.experiment.exp_type, 'Mixed stimuli')
    max_block = ceil(ex.info.trials.max_trials / ex.info.trials.trials_per_block);
    if strcmp(ex.info.experiment.exp_type,'Adaptive')
        for iblock = 1:max_block
            ex.block(iblock).hydrophone.stim_ON_rms_dB_spl = NaN;
            ex.block(iblock).hydrophone.stim_OFF_rms_dB_spl = NaN;
        end
    end
else
    max_block = ex.info.mixed.N_trials_per_file;
    for iblock = 1:max_block
        ex.block(iblock).stim_type = NaN;
        ex.block(iblock).stim_freq = NaN;
        ex.block(iblock).stim_amp = NaN;
        ex.block(iblock).collection_attempts = 0;
        ex.block(iblock).collect_all_valid_trials = 0;
    end
end

%% Trial counter
for iblock = 1:max_block
    % use iblocks but you can get all data easily using all_num_blocks = [ex.block.num_blocks]  % Easy extraction
    ex.block(iblock).water_temp_C = NaN; % Get thermometer working
    ex.block(iblock).jitter = NaN;
    ex.block(iblock).phase_vec = NaN;
    ex.block(iblock).stimulus_block = NaN; % Created in make_scaled_jittered_stim_block, presented via playrec
    ex.block(iblock).across_trial_thresh = NaN;
    ex.block(iblock).within_trial_thresh = NaN;
    ex.block(iblock).kept_trials_idx = NaN;

    %% Raw data
    ex.raw(iblock).hydrophone_mV= NaN;
    ex.raw(iblock).electrodes_microV = NaN; % order follows ex.info.channels.names
    ex.raw(iblock).time_stamp = NaN;
    ex.raw(iblock).loopback = NaN;
end

% Setup noise
ex.noise.starting_rms = NaN;