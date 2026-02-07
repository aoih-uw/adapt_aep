function ex = save_raw_data(ex)
% Generate timestamp
t = datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyyMMdd_HHmmss');
timestamp_str = char(t);

ex.info.experiment.exp_time_end = datestr(t, 'HH:MM:SS');
ex.info.experiment.exp_duration = ex.info.experiment.exp_time_end - ex.info.experiment.exp_time_start;

% Create filename
filename = sprintf('%s_%ddBSPL_raw_data_%s.mat', ex.info.animal.filename_root, ex.info.stimulus.amplitude_spl, timestamp_str);

% Extract only required fields
ex_save = struct();
ex_save.block = ex.block;
ex_save.raw = ex.raw;
ex_save.info = ex.info;
ex_save.health = ex.health;

% Remove stimulus_block from all block entries
for i = 1:length(ex_save.block)
    if isfield(ex_save.block(i), 'stimulus_block')
        ex_save.block(i) = rmfield(ex_save.block(i), 'stimulus_block');
    end
end

% Save
save(filename, 'ex_save');

%% Reset ex structures
ex.raw = ex.raw(1);
ex.raw.hydrophone = NaN;
ex.raw.electrodes = NaN;
ex.raw.time_stamp = NaN;

ex.block = struct();
ex.block(1).water_temp_C = NaN;
ex.block(1).jitter = NaN;
ex.block(1).phase_vec = NaN;
ex.block(1).stimulus_block = NaN;


end
