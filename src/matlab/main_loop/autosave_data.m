function ex = autosave_data(ex,app)
% If in "Adaptive" mode autosave data in a way where you delete the
% "autosave"files
% If in "Timed" or "Static trial count" mode, you don't want to delete the
% autosaves so use "fase" for save_raw_data

if isempty(ex.last_autosave_time)
    ex.last_autosave_time = ex.info.experiment.exp_time_start;
end

now_time = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
fprintf('\nAutosaving data ...\n')
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    if now_time - ex.last_autosave_time >= minutes(15)
        ex = save_raw_data(ex, app, true);
        ex = save_session_data(ex, app, true);
    end
elseif strcmp(ex.info.experiment.exp_type, 'Timed')  || ...
        strcmp(ex.info.experiment.exp_type, 'Static trial count')
    if now_time - ex.last_autosave_time >= minutes(1) || ex.decision(ex.counter.iamp).amp_done == 1
        ex = save_raw_data(ex, app, false);
    end
end

ex.last_autosave_time = now_time;
fprintf('\nAutosaved at %s\n', char(now_time));

