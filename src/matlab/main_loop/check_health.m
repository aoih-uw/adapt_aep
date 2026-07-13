function ex = check_health(ex, app, init_check)
%% Handles variables needed to call measure_EKG and saves EKG signals to ex.health structure
% Assign Variables
ex.counter.ihealth = ex.counter.ihealth + 1;
ihealth = ex.counter.ihealth;

% Alert experimenter will do health check
[y, Fs] = audioread('checking_health.mp3');
sound(y, Fs)

% Measure EKG
[ex, ekg_sig_microV, ekg_rate, ekg_fs_ds, peak_threshold] = measure_EKG(ex,init_check,app);

% Save values to ex
% Check if we are attempting to fill past preallocated spots
if ihealth > ex.info.trials.max_block_health
    idx = ex.info.trials.max_block_health + (1:10); % Add 10 more slots
    [ex.health(idx)] = deal(ex.template.health);
    ex.info.trials.max_block_health = idx(end);
end
ex.health(ihealth).electrodes_microV = ekg_sig_microV; % N_trials, N_samples, N_channels
ex.health(ihealth).time_stamp = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.health(ihealth).ekg_rate = ekg_rate;
ex.health(ihealth).ekg_fs_ds = ekg_fs_ds;

ex.health(ihealth).peak_threshold = peak_threshold;

% Plot ekg rate over time
time_vec = (0:length(ekg_sig_microV)-1)/ekg_fs_ds;
plot(app.UIAxes_health, time_vec, ekg_sig_microV,'-', 'Color', tableau_10('red'))
xlim(app.UIAxes_health,[0 time_vec(end)])
drawnow
