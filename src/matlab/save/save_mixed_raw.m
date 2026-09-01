function ex = save_mixed_raw(ex,app)
%% Saves raw data for mixed stimulus mode
fprintf('\nSaving data...\n')
% Assign variables
iblock = ex.counter.iblock;
ihealth = ex.counter.ihealth;

ex.info.experiment.exp_time_end = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.info.experiment.exp_duration = char(ex.info.experiment.exp_time_end - ex.info.experiment.exp_time_start);
timestamp_str = char(ex.info.experiment.exp_time_end);

% Set folder path and filemenames 
folder = get_subject_folder(ex);
filename = sprintf('%s_raw_data_%s_%s.mat', ex.info.animal.filename_root, ex.info.experiment.test_tag, timestamp_str);

% Extract only required fields
ex_save = struct();
ex_save.info = ex.info; % Basic experiment parameters
ex_save.counter = ex.counter; % Know how many of each thing we did by the time we finished testing this amplitude
ex_save.block_level_info = ex.block(1:iblock); % Block level info

% Remove stimulus_block from all block entries
if isfield(ex_save.block_level_info, 'stimulus_block')
    ex_save.block_level_info = rmfield(ex_save.block_level_info, 'stimulus_block');
end

% Save raw signals
ex_save.raw_signals = ex.raw(1:iblock);

% Save health data
ex_save.health = ex.health(1:ihealth);

% Save
save(fullfile(folder, filename), 'ex_save', '-v7.3');
fullpath = fullfile(folder, filename);
% Ensure file is saved
info = whos('-file', fullpath);
if isempty(info) || ~any(strcmp({info.name}, 'ex_save'))
keyboard
end

% Reset block, health, and counters
ex = setup_block(ex);
ex = setup_analysis(ex);
ex = setup_health(ex);
ex.counter.ihealth = 1;
ex.counter.iblock = 0;
end