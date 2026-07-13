function ex = run_mixed(app)
%% Main experiment function for presenting stimuli of multiple types (Stimulus ON/OFF AND Trimmed)

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
batch_completed = 0;

while ex.counter.ischedule < size(test_schedule,1)
    % Increment counters
    ex.counter.ischedule = ex.counter.ischedule+1;

    %% HEALTH CHECK
    time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.health(ex.counter.ihealth).time_stamp;
    if time_diff >= minutes(15)
        fprintf('\nChecking animal health...\n')
        ex = check_health(ex,app,0);
    end

    %% TRACK TEMPERATURE
    fprintf('\nChecking temperature...\n')
    if isnat(ex.last_temp_check)
        ex.last_temp_check = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    end
    time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.last_temp_check;
    if time_diff >= minutes(15)
        [y, Fs] = audioread('tank_temp.mp3');
        sound(y, Fs)
    end

    %% DATA COLLECTION
    while ~batch_completed
        %% CREATE BLOCK OF TRIALS
        fprintf('\nCreating trial block...\n')
        ex.counter.iblock = ex.counter.iblock + 1; % iblock resets after every saved batch of data
        ex.counter.grand_iblock = ex.counter.grand_iblock + 1; % grand_iblock never resets
        ex = create_new_stimuli_block(ex,app);

        fprintf('\nPresenting stimulus...\n')
        ex = setup_experiment_present_sound(ex,app); % Present stimuli and measure signals

        % REJECT ARTEFACTS
        fprintf('\nRejecting artefacts...\n')
        ex = reject_artefacts_mixed(ex,app);

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

    %% SAVE RAW DATA IF DONE WITH SCHEDULE
    if ex.counter.iblock >= (ex.info.mixed.N_trials_per_file/ex.info.trials.trials_per_block) || ...
            ex.counter.ischedule == size(test_schedule,1)
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