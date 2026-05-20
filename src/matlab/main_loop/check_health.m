function ex = check_health(ex)
%% Present stimulus and measure response
% Load variables
ex.counter.ihealth = ex.counter.ihealth + 1;
ihealth = ex.counter.ihealth;
EKG_idx = 3;

% Measure EKG
[ex, rec_data_mV] = measure_EKG(ex);

% Save values to ex
ex.health(ihealth).electrodes_microV = rec_data_mV(:,:,3).*1e3; % N_trials, N_samples, N_channels
ex.health(ihealth).time_stamp = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');

if ihealth > 1
    answer = input('Based on EKG results, continue testing? (y/n): ', 's');
    if strcmpi(answer, 'y')
        ex.exp_done = 0;
    else
        ex.exp_done = 1;
    end
end


