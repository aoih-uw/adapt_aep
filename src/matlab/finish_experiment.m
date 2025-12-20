function ex = finish_experiment(ex)
t = datetime('now', 'TimeZone', 'UTC', 'Format', 'yyyy-MM-dd HH:mm:ss');

ex.info.experiment.exp_time_end = datestr(t, 'HH:MM:SS');
ex.info.experiment.exp_duration = ex.info.experiment.exp_time_end - ex.info.experiment.exp_time_start;

% Pop-up reminding to measure the standard length and weight

% Pop-up asking for final notes about experiment