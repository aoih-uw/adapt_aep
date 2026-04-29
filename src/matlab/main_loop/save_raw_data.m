function ex = save_raw_data(ex, is_autosave)
if nargin < 2, is_autosave = false; end
iblock = ex.counter.iblock;
ihealth = ex.counter.ihealth;
iboot = ex.counter.iboot;
iamp = ex.counter.iamp;

% Generate timestamp
ex.info.experiment.exp_time_end = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.info.experiment.exp_duration = char(ex.info.experiment.exp_time_end - ex.info.experiment.exp_time_start);
timestamp_str = char(ex.info.experiment.exp_time_end);

% Find folder
folder = get_subject_folder(ex);

if is_autosave
    filename = sprintf('%s_%ddBSPL_raw_data_AUTOSAVE_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, timestamp_str);
else
    filename = sprintf('%s_%ddBSPL_raw_data_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, timestamp_str);
end

% Extract only required fields
ex_save = struct();
ex_save.info = ex.info; % Basic experiment parameters
ex_save.counter = ex.counter; % Know how many of each thing we did by the time we finished testing this amplitude
ex_save.block_level_info = ex.block(1:iblock); % Block level info
ex_save.raw_signals = ex.raw(1:iblock); % The raw signals
ex_save.preprocessing_stats = ex.preprocess(1:iblock); % Preprocessing statistics
ex_save.decision = ex.decision(iamp); % Decisions related to this specific stimulus amplitude and frequency

ex_save.kept = ex.kept; % Save the latest round of preprocessed signals
ex_save.kept = rmfield(ex_save.kept, 'trials'); % Don't need these
ex_save.kept = rmfield(ex_save.kept, 'trials_weighted');

ex_save.health = ex.health(1:ihealth);
ex_save.health = rmfield(ex_save.health, 'hydrophone_mV'); % Don't need these
ex_save.health = rmfield(ex_save.health, 'electrodes_microV');
ex_save.health = rmfield(ex_save.health, 'loopback');

ex_save.fft = ex.fft;
ex_save.bootstrap = ex.boot(1:iboot);

% Remove stimulus_block from all block entries
if isfield(ex_save.block_level_info, 'stimulus_block')
    ex_save.block_level_info = rmfield(ex_save.block_level_info, 'stimulus_block');
end

% Save
save(fullfile(folder, filename), 'ex_save');

%% Save figures and reset block
if ~is_autosave
    save_raw_figures(ex,folder)
    delete_autosaves(folder, ex.info.animal.filename_root);
    ex = setup_block(ex);
    ex = setup_analysis(ex);
end

end
