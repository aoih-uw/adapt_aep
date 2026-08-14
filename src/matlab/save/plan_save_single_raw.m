function ex = plan_save_single_raw(ex,app)
%% Plan how raw data will be saved in single stimulus mode
every_min = 15;
every_block = 20; % Save every 20 blocks for timed mode
if isempty(ex.last_autosave_time)
    ex.last_autosave_time = ex.info.experiment.exp_time_start;
end
iblock = ex.counter.iblock;

now_time = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
if strcmp(ex.info.experiment.exp_type,'Adaptive')
    if ex.decision(ex.counter.iamp).amp_done == 1 % Done testing at this amplitude
        fprintf('\nSaving data ...\n')
        ex = save_single_raw(ex, app, false);
        ex.last_autosave_time = now_time;
    elseif now_time - ex.last_autosave_time >= minutes(every_min)
        fprintf('\nAutosaving data ...\n')
        ex = save_single_raw(ex, app, true);
        ex = save_session_data(ex, app, true);
        ex.last_autosave_time = now_time;
    end
elseif strcmp(ex.info.experiment.exp_type, 'Timed')
    if mod(iblock,every_block) == 0 || ex.decision(ex.counter.iamp).amp_done == 1
        % save in regular intervals and also when the amp is done to make
        % sure you got all trials even between the last autosave and when the experiment ends
        fprintf('\nSaving data ...\n')
        ex = save_single_raw(ex, app, false);
        ex.last_autosave_time = now_time;
    end
elseif strcmp(ex.info.experiment.exp_type, 'Static trial count')
    if ex.decision(ex.counter.iamp).amp_done == 1
        % We are done collecting data, no need to autosave
        fprintf('\nSaving data ...\n')
        ex = save_single_raw(ex, app, false);
        ex.last_autosave_time = now_time; % Reset for next set
    elseif now_time - ex.last_autosave_time >= minutes(every_min)
        % Autosave
        fprintf('\nAutosaving data ...\n')
        ex = save_single_raw(ex, app, true);
        ex.last_autosave_time = now_time;
    end
end


