function ex = experimenter_reminders(ex)
%% Helper function for reminding the experimenter to do these tasks

% INSPECT SIGNALS
if isnat(ex.last_signal_inspection)
    ex.last_signal_inspection = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
end
time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.last_signal_inspection;
if time_diff >= minutes(5)
    % Alert experimenter
    fprintf('\nInspect signals\n')
    beep; pause(1); beep; pause(1);
    ex.last_signal_inspection = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
end

% TRACK TEMPERATURE
if isnat(ex.last_temp_check)
    ex.last_temp_check = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
end
time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.last_temp_check;
if time_diff >= minutes(15)
    % Alert experimenter
    beep; pause(1); beep; pause(1);
    fprintf('\nDocument temperature\n')
    ex.last_temp_check = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
end
end