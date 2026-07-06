function ex = setup_health(ex)
%% Setup health field of ex structure
% If we have already measured health of subject once in this experiment
% we need to reset and include values from the last health check

% Set maximum block numbers to be preallocated
if ~strcmp(ex.info.experiment.exp_type, 'Mixed stimuli')
    max_block_health = ceil(ex.info.trials.max_trials / ex.info.trials.trials_per_block);
    ex.info.trial.max_block_health = max_block_health;
else
    max_block_health = ceil(ex.info.mixed.N_trials_per_file/ ex.info.trials.trials_per_block);
    ex.info.trial.max_block_health = max_block_health;
end

if ex.counter.ihealth > 0
    if isfield(ex.health(ex.counter.ihealth), 'time_stamp')
        ex.health(1).time_stamp = ex.health(ex.counter.ihealth).time_stamp;
        ex.health(1).electrodes_microV = ex.health(ex.counter.ihealth).electrodes_microV;
        ex.health(1).ekg_rate =  ex.health(ex.counter.ihealth).ekg_rate;
        ex.health(1).ekg_fs_ds =  ex.health(ex.counter.ihealth).ekg_fs_ds;
        ex.health(1).peak_threshold =  ex.health(ex.counter.ihealth).peak_threshold;
        for ihealth = 2:max_block
            ex.health(ihealth).time_stamp = NaN;
            ex.health(ihealth).electrodes_microV= NaN;
            ex.health(ihealth).ekg_rate = NaN;
            ex.health(ihealth).ekg_fs_ds = NaN;
            ex.health(ihealth).peak_threshold = NaN;
        end
    end
else % We are setting up the health field for the first time, so we need to build it from scratch
    for ihealth = 1:max_block
        ex.health(ihealth).time_stamp = NaN;
        ex.health(ihealth).electrodes_microV= NaN;
        ex.health(ihealth).ekg_rate = NaN;
        ex.health(ihealth).ekg_fs_ds = NaN;
        ex.health(ihealth).peak_threshold = NaN;
    end
    ex.template.health = ex.health(1);
end
