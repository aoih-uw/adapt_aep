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
ex.save.stimulus_frequency = ex.info.stimulus.frequency_hz;
ex_save.total_trial_count = sum(ex.trial_count(1:iamp));

% Keep ex.info but exclude ex.info.stimulus
ex_save.info = ex.info;
ex_save.info = rmfield(ex_save.info.stimulus, 'amplitude_spl');

% Save decision
ex_save.decision

% Save model info from ex_save.model
ex_save.model = ex.model;

% Save the filtered ex structure
save(fullfile(folder, filename), 'ex_save');

% Delete autosaves and save figures
if ~is_autosave
    save_session_figures(ex,folder,app)
    delete_autosaves(folder, ex.info.animal.filename_root);
end
end