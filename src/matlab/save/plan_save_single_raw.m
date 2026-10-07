function ex = plan_save_single_raw(ex,app)
%% Plan how raw data will be saved in single stimulus mode
every_block = 20; % Save every 20 blocks for timed mode
if isempty(ex.last_autosave_time)
    ex.last_autosave_time = ex.info.experiment.exp_time_start;
end
iblock = ex.counter.iblock;

now_time = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
if strcmp(ex.info.experiment.exp_type, 'Timed')
    if mod(iblock,every_block) == 0 || ex.decision(ex.counter.iamp).amp_done == 1
        % save in regular intervals and also when the amp is done to make
        % sure you got all trials even between the last autosave and when the experiment ends
        fprintf('\nSaving data ...\n')
        ex = save_single_raw(ex, app, false);
        ex.last_autosave_time = now_time;
    end
end


