function ex = check_health(ex, app)
%% Present stimulus and measure response
% Load variables
ex.counter.ihealth = ex.counter.ihealth + 1;
ihealth = ex.counter.ihealth;
EKG_idx = 3; % 3rd channel in the output. 

% Measure EKG
[ex, ekg_sig, ekg_mean, ekg_rng] = measure_EKG(ex);

% Save values to ex
ex.health(ihealth).electrodes_microV = ekg_sig; % N_trials, N_samples, N_channels
ex.health(ihealth).time_stamp = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex.health(ihealth).ekg_rate = ekg_mean;
ex.health(ihealth).ekg_rng = ekg_rng;

% Plot ekg rate over time
ekg_rate_vec = cat(1, ex.health(1:ihealth).ekg_rate);
ekg_rng_vec  = cat(1, ex.health(1:ihealth).ekg_rng);
yneg = ekg_rate_vec(:) - ekg_rng_vec(:,1);
ypos = ekg_rng_vec(:,2) - ekg_rate_vec(:);

errorbar(app.UIAxes_health, 1:length(ekg_rate_vec), ekg_rate_vec, yneg, ypos, 'o-', 'Color', ...
    tableau_10('red'), 'MarkerFaceColor', tableau_10('red'), 'MarkerEdgeColor', tableau_10('red'), 'MarkerSize', 14)
% if ihealth > 1
%     answer = input('Based on EKG results, continue testing? (y/n): ', 's');
%     while ~strcmpi(answer, 'y') && ~strcmpi(answer, 'n')
%         answer = input('Invalid response. Please try again (y/n): ', 's');
%     end
%     if strcmpi(answer, 'y')
%         ex.exp_done = 0;
%     else
%         ex.amp_done = 1;
%         ex.exp_done = 1;
%     end
% end


