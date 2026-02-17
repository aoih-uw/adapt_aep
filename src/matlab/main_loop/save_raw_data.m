function ex = save_raw_data(ex)
iblock = ex.counter.iblock;
% Generate timestamp
t = datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyyMMdd_HHmmss');
timestamp_str = char(t);

ex.info.experiment.exp_time_end = datestr(t, 'HH:MM:SS');
ex.info.experiment.exp_duration = ex.info.experiment.exp_time_end - ex.info.experiment.exp_time_start;

% Create filename
filename = sprintf('%s_%ddBSPL_raw_data_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, timestamp_str);

% Extract only required fields
ex_save = struct();
ex_save.info = ex.info;
ex_save.block = ex.block(1:iblock);
ex_save.raw = ex.raw(1:iblock);
ex_save.health = ex.health(1:iblock);

% Remove stimulus_block from all block entries
for i = 1:length(ex_save.block)
    if isfield(ex_save.block(i), 'stimulus_block')
        ex_save.block(i) = rmfield(ex_save.block(i), 'stimulus_block');
    end
end

% Save
save(filename, 'ex_save');

% Reset block
ex = setup_block(ex);

end
