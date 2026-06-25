function ex = run_mixed(app)
%% run_single presents stimuli of both types (Stimulus ON/OFF and Trimmed)

% DO YOUR BEST!
fprintf('  \n')
fprintf('                \n')
fprintf('   Do your best!    \n')
fprintf('          \n')
fprintf('   .-*''`    `*-.._.-''/\n')
fprintf(' < o ))     ,       (\n')
fprintf('   `*-._`._(__.--*"`.\\\n')
fprintf('\n')

ex = app.ex;
ex.info.experiment.exp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
test_schedule = ex.info.mixed.test_schedule;

while ex.counter.ischedule < size(test_schedule,1)
    % Increment counters
    ex.counter.ischedule = ex.counter.ischedule+1;

    %% HEALTH CHECK
        time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.health(ex.counter.ihealth).time_stamp;
        if time_diff >= minutes(10)
            fprintf('\nChecking animal health...\n')
            ex = check_health(ex,app,0);
        end

        %% READ THERMOMETER
        fprintf('\nChecking temperature...\n')
        % ex = check_temperature(ex);

        %% CREATE BLOCK OF TRIALS
        fprintf('\nCreating trial block...\n')
        ex.counter.iblock = ex.counter.iblock + 1;
        ex = create_new_stimuli_block(ex,app);

        %% DATA COLLECTION 
        while ~batch_completed
            fprintf('\nPresenting stimulus...\n')
            ex = setup_experiment_present_sound(ex,app); % Present stimuli and measure signals

            % REJECT ARTEFACTS
            fprintf('\Rejecting artefacts...\n')
            ex = reject_mixed_artefacts(ex,app);

            if ex.counter.N_not_enough_trials > 0
                fprintf('Insufficient valid trials: Reattempting %d', ex.counter.N_not_enough_trials)
            elseif ex.counter.N_not_enough_trials == 0 
                batch_completed = 1;
            end
        end
        % Reset marker
        batch_completed = 0;
        
        %% COUNT TRIALS
        ex = count_mixed_trials(ex,app);

        %% SAVE RAW DATA
        if ex.counter.iblock >= ex.info.mixed.N_trials_per_file || ex.counter.ischedule == size(test_schedule,1)
        ex = save_mixed_raw(ex,app);
        end

         %% CHECK IF USER PRESSED PAUSE
        if app.PauseFlag
            [y, Fs] = audioread('step.mp3');
            sound(y, Fs)
            [action, ex] = pause_dialog(ex,app);
            app.PauseFlag = false;  % Reset pause flag
            if strcmp(action, 'stop')
                return
            elseif strcmp(action, 'change')
                continue
            end
            % If 'continue', proceed normally
        end
end