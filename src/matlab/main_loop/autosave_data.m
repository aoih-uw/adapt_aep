function ex = autosave_data(ex,app)
    if isempty(ex.last_autosave_time)
        ex.last_autosave_time = ex.info.experiment.exp_time_start;
    end
    
    now_time = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    if now_time - ex.last_autosave_time >= minutes(15)
        fprintf('\nAutosaving data ...\n')
        ex = save_raw_data(ex, app, true);
        if strcmp(ex.info.experiment.exp_type,'Adaptive')
            ex = save_session_data(ex, app, true);
        end
        ex.last_autosave_time = now_time;
        fprintf('\nAutosaved at %s\n', char(now_time));
    end
end