function ex = setup_ex(app)
%% Create ex structure
% Iteration Counters
ex.counter.iamp = 0;
ex.counter.iblock = 0;
ex.counter.ihealth = 0;

% Experiment mode specific counters
if strcmp(app.DropDown_test_mode.Value,'Adaptive')
    ex.counter.iboot = 0;
elseif strcmp(app.DropDown_test_mode.Value,'Mixed freqs')
    ex.counter.ischedule = 0;
    ex.counter.N_not_enough_trials = 0;
end
if strcmp(app.DropDown_test_mode.Value,'Mixed freqs') || strcmp(app.DropDown_test_mode.Value,'Timed')
        ex.counter.grand_iblock = 0;
end

% Experiment State Markers
ex.exp_done = 0;
ex.test = 0;
ex.last_autosave_time = [];
ex.no_valid_trials = 0;
ex.last_temp_check = NaT;
ex.last_signal_inspection = NaT;

% Trial counter
if ~strcmp(app.DropDown_test_mode.Value,'Mixed freqs')
    for iamp = 1:100
        ex.trial_count(iamp) = 0;
        ex.decision(iamp).resp_found = 0;
        ex.decision(iamp).current_amplitude = NaN; %# have this assigned when resp_found is assigned as well in separate, subtract, bootstrap etc. etc.!
        ex.decision(iamp).amp_done = 0;
        ex.decision(iamp).amp_done_reason = NaN;
    end
end
end