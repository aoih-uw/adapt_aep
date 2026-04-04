function ex = save_session_data(ex, app, is_autosave)
if nargin < 3, is_autosave = false; end
iamp = ex.counter.iamp;

% Generate timestamp
ex.info.experiment.exp_time_end = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.info.experiment.exp_duration = char(ex.info.experiment.exp_time_end - ex.info.experiment.exp_time_start);
timestamp_str = char(ex.info.experiment.exp_time_end);

% Find folder
folder = get_subject_folder(ex);

if ~is_autosave % This is the final save for this session
    % Pop-up asking for final notes about experiment (moved before saving)
    [y, Fs] = audioread('step.mp3');
    sound(y, Fs)
    answer = inputdlg('Enter notes about the experiment:', 'Experiment Notes', [10 80]);
    if ~isempty(answer)
        ex.info.experiment.notes = answer{1};
    else
        ex.info.experiment.notes = '';
    end
end

if is_autosave
    filename = sprintf('%s_session_data_AUTOSAVE_%s.mat', ex.info.animal.filename_root, timestamp_str);
else
    filename = sprintf('%s_session_data_%s.mat', ex.info.animal.filename_root, timestamp_str);
end

% Create a copy of ex to modify for saving
ex_save = struct();

% Keep specified top-level fields
ex_save.total_trial_count = sum(ex.trial_count(1:iamp));

% Keep ex.info but exclude ex.info.stimulus
ex_save.info = ex.info;
if isfield(ex_save.info, 'stimulus')
    ex_save.info = rmfield(ex_save.info, 'stimulus');
end

% Remove fields from ex_save.model
ex_save.model = ex.model;
fields_to_remove = {'doub_freq_diff_vec_temp', 'doub_freq_dur_vec_temp', 'noise_floor_temp', 'doub_freq_resp_vec_mV', 'noise_floor'};
for i = 1:length(fields_to_remove)
    if isfield(ex_save.model, fields_to_remove{i})
        ex_save.model = rmfield(ex_save.model, fields_to_remove{i});
    end
end

% Keep ex.preprocess with the specific fields you're updating
ex_save.preprocess = ex.preprocess;
fields_to_remove_preprocess = {'kept_phases', 'kept_jitter', 'kept_channels'};
for i = 1:length(fields_to_remove_preprocess)
    if isfield(ex_save.preprocess, fields_to_remove_preprocess{i})
        ex_save.preprocess = rmfield(ex_save.preprocess, fields_to_remove_preprocess{i});
    end
end

% Save the filtered ex structure
save(fullfile(folder, filename), 'ex_save');

% Delete autosaves and save figures
if ~is_autosave
    save_session_figures(ex,folder,app)
    delete_autosaves(folder, ex.info.animal.filename_root);
end
end