function ex = save_raw_data(ex, is_autosave)
if nargin < 2, is_autosave = false; end
iblock = ex.counter.iblock;

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
ex_save.info = ex.info;
ex_save.block = ex.block(1:iblock);
ex_save.raw = ex.raw(1:iblock);
ex_save.health = ex.health(1:iblock);

% Remove stimulus_block from all block entries
if isfield(ex_save.block, 'stimulus_block')
    ex_save.block = rmfield(ex_save.block, 'stimulus_block');
end

% Save
save(fullfile(folder, filename), 'ex_save');

%% Save figures and reset block
if ~is_autosave
    save_raw_figures(ex,folder)
    delete_autosaves(folder, ex.info.animal.filename_root);
    ex = setup_block(ex);
end

end
