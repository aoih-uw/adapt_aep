function ex = setup_block(ex)
%% Setup block-level fields in ex structure
% Per block metadata
if ~strcmp(ex.info.experiment.exp_type, 'Mixed stimuli')
    max_block = ceil(ex.info.trials.max_trials / ex.info.trials.trials_per_block);
    ex.info.trials.max_block = max_block;
else
    max_block = ceil(ex.info.mixed.N_trials_per_file/ ex.info.trials.trials_per_block);
    ex.info.trials.max_block = max_block;
    for iblock = 1:max_block
        ex.block(iblock).stim_type = NaN;
        ex.block(iblock).stim_amp = NaN;
        ex.block(iblock).collection_attempts = 0;
    end
end

if isfield(ex,'block')
    if size(ex.block,2) > max_block
        ex.block = ex.block(:,1:max_block);
        ex.raw = ex.block(:,1:max_block);
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
    ex.block(iblock).kept_trials_idx = NaN;

    % Hydrophone signal quality
    ex.block(iblock).hydrophone.stimulus_rms = NaN;
    ex.block(iblock).hydrophone.tank_nf_rms = NaN;
    ex.block(iblock).hydrophone.stimulus_rms_mad = NaN;
    ex.block(iblock).hydrophone.tank_nf_rms_mad = NaN;
    ex.block(iblock).hydrophone.stim_ON_snr_median = NaN;
    ex.block(iblock).hydrophone.stim_ON_snr_mad = NaN;

    %% Raw data
    ex.raw(iblock).hydrophone_mV= NaN;
    ex.raw(iblock).electrodes_microV = NaN; % order follows ex.info.channels.names
    ex.raw(iblock).time_stamp = NaN;
    ex.raw(iblock).loopback = NaN;
end

% Setup noise
ex.noise.starting_rms = NaN;

% Create a template of the raw and block fields
ex.template.block = ex.block(1);
ex.template.raw = ex.raw(1);