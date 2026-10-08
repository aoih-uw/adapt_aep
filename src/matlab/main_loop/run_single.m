function ex = run_single(app)
%% Main experiment function for presenting stimuli of a single type (Stimulus ON/OFF or Trimmed)
%% Notes:
% 10/8/26: Currently timed mode does not support accelerometer
% measurements, you must do it in mixed mode

% DO YOUR BEST!
fprintf('  \n')
fprintf('                \n')
fprintf('   Do your best!    \n')
fprintf('          \n')
fprintf('   .-*''`    `*-.._.-''/\n')
fprintf(' < o ))     ,       (\n')
fprintf('   `*-._`._(__.--*"`.\\\n')
fprintf('\n')

% Setup ex structure
ex = app.ex;
ex.info.experiment.exp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');

% Select 140 dB automatically for timed
if strcmp(app.DropDown_test_mode.Value, 'Timed')
    ex.info.stimulus.amplitude_spl = 140;
end

while ~ex.exp_done % While testing current stimulus frequency
    %% Increment counters
    ex.counter.iamp = ex.counter.iamp + 1;
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.decision(ex.counter.iamp).amp_done = 0;
    ex.counter.iblock = 0;
    ex.info.experiment.amp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');

    while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude
        %% CHECK HEALTH
        ex = check_health(ex,app,0);

        %% CREATE BLOCK OF TRIALS
        ex.counter.iblock = ex.counter.iblock + 1;
        if strcmp(app.DropDown_test_mode.Value, 'Timed')
            ex.counter.grand_iblock = ex.counter.grand_iblock + 1;
        end
        ex = create_new_stimuli_block(ex,app);

        %% DATA COLLECTION
        ex = setup_experiment_present_sound(ex,app); % Present stimuli and measure signals

        %% DATA PRE-PROCESSING
        ex = preprocess_signal(ex,app);

        %% CHECK IF MAX (VALID) TRIALS PRESENTED OR TIME LIMIT MET
        if strcmp(app.DropDown_test_mode.Value, 'Timed')
            if datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.info.experiment.amp_time_start >= minutes(ex.info.experiment.timer_dur_min)
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus(1).amplitude_spl;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Experiment time reached';
            end
        end

        % Progression counter
        fprintf('  b%d·a%d\n', ex.counter.iblock, ex.counter.iamp);

        %% SAVE RAW DATA
        ex = plan_save_single_raw(ex,app);

        %% CONTINUE TESTING?
        if ex.decision(ex.counter.iamp).amp_done == 1
            if strcmp(app.DropDown_test_mode.Value, 'Timed')
                % Do not allow testing at a different amplitude at this time
                % If I do, then I need to restructure some code particularly counters!
                return
            end
        end
    end
end


