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

    %% REMINDERS

    % HEALTH
    time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.health(ex.counter.ihealth).time_stamp;
    if time_diff >= minutes(15)
        fprintf('\nChecking animal health...\n')
        ex = check_health(ex,app,0);
    end

    % INSPECT SIGNALS
    if isnat(ex.last_signal_inspection)
        ex.last_signal_inspection = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    end
    time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.last_signal_inspection;
    if time_diff >= minutes(5)
        [y, Fs] = audioread('inspect_sigs.mp3');
        sound(y, Fs)
        ex.last_signal_inspection = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    end

    % TRACK TEMPERATURE
    fprintf('\nChecking temperature...\n')
    if isnat(ex.last_temp_check)
        ex.last_temp_check = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    end
    time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.last_temp_check;
    if time_diff >= minutes(15)
        [y, Fs] = audioread('tank_temp.mp3');
        sound(y, Fs)
        ex.last_temp_check = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    end

    %% INCREMENT ISCHEDULE
    ex.counter.ischedule = ex.counter.ischedule+1;
    
    % Check if we already have enough trials for this stimulus type
    N_trials_needed = ex.info.mixed.test_schedule(ex.counter.ischedule,3);
    cur_stim_id = ex.info.mixed.test_schedule(ex.counter.ischedule,4);
    
    if ex.info.mixed.trial_counter(cur_stim_id) < N_trials_needed
        while ~batch_completed
            %% CREATE BLOCK OF TRIALS
            fprintf('\nCreating trial block...\n')
            ex.counter.iblock = ex.counter.iblock + 1; % iblock resets after every saved batch of data
            ex.counter.grand_iblock = ex.counter.grand_iblock + 1; % grand_iblock never resets
            ex = create_new_stimuli_block(ex,app);

            fprintf('\nPresenting stimulus...\n')
            ex = setup_experiment_present_sound(ex,app); % Present stimuli and measure signals

            %% REJECT ARTEFACTS
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
    else
        fprintf('Collected enough trials for current stimulus type, skipping current ischedule\n')
    end

    % REPORT PROGRESS
    fprintf('Experiment progress: %1.2f%% complete\n', (ex.counter.ischedule/size(test_schedule,1)*100));

    %% SAVE RAW DATA
    if ex.counter.iblock > 0 % Only save if there is data in the block structure
        if ex.counter.iblock >= (ex.info.mixed.N_trials_per_file/ex.info.trials.trials_per_block) || ...
                ex.counter.ischedule == size(test_schedule,1)
            ex = save_mixed_raw(ex,app);
        end
    end
end