function ex = save_single_raw(ex, app, is_autosave)
%% Saves raw data for single stimulus mode
if nargin < 3, is_autosave = false; end

% Assign variables
iblock = ex.counter.iblock;
ihealth = ex.counter.ihealth;
iamp = ex.counter.iamp;
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    iboot = ex.counter.iboot;
end

% Generate timestamp
ex.info.experiment.exp_time_end = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.info.experiment.exp_duration = char(ex.info.experiment.exp_time_end - ex.info.experiment.amp_time_start);
timestamp_str = char(ex.info.experiment.exp_time_end);

% Find folder
folder = get_subject_folder(ex);

if is_autosave
    filename = sprintf('%s_%ddBSPL_raw_data_%s_AUTOSAVE_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, ex.info.experiment.test_tag, timestamp_str);
else
    filename = sprintf('%s_%ddBSPL_raw_data_%s_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, ex.info.experiment.test_tag, timestamp_str);
end

% Extract only required fields
ex_save = struct();
ex_save.info = ex.info; % Basic experiment parameters
ex_save.counter = ex.counter; % Know how many of each thing we did by the time we finished testing this amplitude
ex_save.trial_count = ex.trial_count(1:iamp);
ex_save.block_level_info = ex.block(1:iblock); % Block level info

% Remove stimulus_block from all block entries
if isfield(ex_save.block_level_info, 'stimulus_block')
    ex_save.block_level_info = rmfield(ex_save.block_level_info, 'stimulus_block');
end

% Save raw signals
ex_save.raw_signals = ex.raw(1:iblock);

% Save health data
ex_save.health = ex.health(1:ihealth);

% Adaptive program specific
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    ex_save.fft = ex.fft;
    ex_save.bootstrap = ex.bootstrap(1:iboot);
    ex_save.decision = ex.decision(iamp); % Decisions related to this specific stimulus amplitude and frequency
end

% Save
save(fullfile(folder, filename), 'ex_save', '-v7.3');

%% Save figures and reset block
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    if ex.decision(ex.counter.iamp).amp_done == 1 % Reset only when testing at this amp is done
        save_adaptive_figures(ex,folder)
        delete_autosaves(folder, ex.info.animal.filename_root);

        % Reset ex layers
        ex = setup_block(ex);
        ex = setup_analysis(ex);

        % Reset health and counters
        ex = setup_health(ex);
        ex.counter.ihealth = 1;
        ex.counter.iblock = 0;
    end
elseif strcmp(ex.info.experiment.exp_type,'Timed') % Reset every time autosave is called, no autosave files to remove
    % Only reset when we are continuing to test at this amplitude
    if ex.decision(ex.counter.iamp).amp_done == 0
    % Reset ex and counters
    ex = setup_block(ex);
    ex = setup_health(ex);
    ex.counter.ihealth = 1;
    ex.counter.iblock = 0;
    end

elseif strcmp(ex.info.experiment.exp_type,'Static trial count') % Reset only when testing at this amp is done
    if ex.decision(ex.counter.iamp).amp_done == 1
        delete_autosaves(folder, ex.info.animal.filename_root);

        % Reset ex and counters
        ex = setup_block(ex);
        ex = setup_health(ex);
        ex.counter.ihealth = 1;
        ex.counter.iblock = 0;
    end
end
end

