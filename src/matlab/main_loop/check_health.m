function ex = check_health(ex, app, init_check)
%% Handles variables needed to call measure_EKG and saves EKG signals to ex.health structure
% Assign Variables
ex.counter.ihealth = ex.counter.ihealth + 1;
ihealth = ex.counter.ihealth;
EKG_idx = 3; % 3rd channel in the output. 
manual_select = 0; % Marker for manually selecting peak_threshold

% Alert experimenter will do health check
[y, Fs] = audioread('button_press.mp3');
sound(y, Fs)

% Extract peak_threshold value if present
if init_check
    input_peak_threshold = [];
elseif ihealth > 0
    if ~isnan(ex.health(ihealth-1).peak_threshold)
        input_peak_threshold = ex.health(ihealth-1).peak_threshold;
        if isnan(input_peak_threshold)
            input_peak_threshold = [];
        end
    else
        input_peak_threshold = [];
    end
else
    input_peak_threshold = [];
end


% Measure EKG
[ex, ekg_sig, ekg_rate, ekg_fs_ds, peak_threshold] = measure_EKG(ex,init_check,input_peak_threshold);

% Save values to ex
ex.health(ihealth).electrodes_microV = ekg_sig; % N_trials, N_samples, N_channels
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


