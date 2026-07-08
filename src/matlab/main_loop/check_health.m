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
ekg_rate_vec = cat(1, ex.health(1:ihealth).ekg_rate);
plot(app.UIAxes_health, 1:length(ekg_rate_vec), ekg_rate_vec,'o-', 'Color', ...
    tableau_10('red'), 'MarkerFaceColor', tableau_10('red'), 'MarkerEdgeColor', tableau_10('red'), 'MarkerSize', 14)
xlim(app.UIAxes_health,[0.5, ihealth+0.5])
ylim(app.UIAxes_health,[min(ekg_rate_vec)-2 max(ekg_rate_vec)+2])


