function ex = save_session_data(ex)
iamp = ex.counter.iamp;

% Save time information
t = datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd HH:mm:ss');
ex.info.experiment.exp_time_end = datestr(t, 'HH:MM:SS');

exp_time_start = duration(ex.info.experiment.exp_time_start, 'InputFormat', 'hh:mm:ss');
exp_time_end = duration(ex.info.experiment.exp_time_end, 'InputFormat', 'hh:mm:ss');
ex.info.experiment.exp_duration = char(exp_time_end - exp_time_start);

% Pop-up asking for final notes about experiment (moved before saving)
answer = inputdlg('Enter notes about the experiment:', 'Experiment Notes', [10 80]);
if ~isempty(answer)
    ex.info.experiment.notes = answer{1};
else
    ex.info.experiment.notes = '';
end

% Create filename
timestamp_str = datestr(now, 'yyyymmdd_HHMMSS');
filename = sprintf('%s_session_data_%s.mat', ex.info.animal.filename_root, timestamp_str);

% Create a copy of ex to modify for saving
ex_save = struct();

% Keep specified top-level fields
ex_save.trial_count = ex.trial_count(iamp);
ex_save.model = ex.model;
ex_save.decision = ex.decision(iamp);
ex_save.slope = ex.slope;

% Keep ex.info but exclude ex.info.stimulus
ex_save.info = ex.info;
if isfield(ex_save.info, 'stimulus')
    ex_save.info = rmfield(ex_save.info, 'stimulus');
end

% Keep ex.preprocess with the specific fields you're updating
ex_save.preprocess = ex.preprocess;

% Remove the fields that shouldn't be included from preprocess(1)
if length(ex_save.preprocess) >= 1
    if isfield(ex_save.preprocess(1), 'kept_phases')
        ex_save.preprocess(1) = rmfield(ex_save.preprocess(1), 'kept_phases');
    end
    if isfield(ex_save.preprocess(1), 'kept_jitter')
        ex_save.preprocess(1) = rmfield(ex_save.preprocess(1), 'kept_jitter');
    end
    if isfield(ex_save.preprocess(1), 'kept_channels')
        ex_save.preprocess(1) = rmfield(ex_save.preprocess(1), 'kept_channels');
    end
end

% Remove fields from ex_save.model
if isfield(ex_save.model, 'doub_freq_resp_vec_mV')
    ex_save.model = rmfield(ex_save.model, 'doub_freq_resp_vec_mV');
end
if isfield(ex_save.model, 'noise_floor')
    ex_save.model = rmfield(ex_save.model, 'noise_floor');
end

% Save the filtered ex structure
save(filename, 'ex_save');
fprintf('Session data saved to: %s\n', filename);

ex.slope.doub_freq = [];
ex.slope.other_freqs = [];
ex.slope.doub_freq_std = [];
ex.slope.other_freqs_std = [];
ex.slope.other_freqs_stderr = [];

end