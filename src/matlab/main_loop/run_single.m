function ex = run_single(app)
%% Main experiment function for presenting stimuli of a single type (Stimulus ON/OFF or Trimmed)

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
ex = select_next_dialog(ex);

while ~ex.exp_done % While testing current stimulus frequency
    ex.counter.iamp = ex.counter.iamp + 1;
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.decision(ex.counter.iamp).amp_done = 0;
    ex.counter.iblock = 0;
    if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
        ex.counter.iboot = 0;
    end
    ex.info.experiment.amp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');

    %% UPDATE GUI
    app.Label_current_amp.Text = string(ex.info.stimulus.amplitude_spl);

    %% INSPECT SIGNALS REMINDER
    if isnat(ex.last_signal_inspection)
        ex.last_signal_inspection = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
    end
    time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.last_signal_inspection;
    if time_diff >= minutes(5)
        [y, Fs] = audioread('inspect_sigs.mp3');
        sound(y, Fs)
        ex.last_signal_inspection = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss'); 
    end
    
    while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude
        %% HEALTH CHECK
        time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.health(ex.counter.ihealth).time_stamp;
        if strcmp(app.DropDown_test_mode.Value, 'Timed')
            if time_diff >= minutes(15)
                fprintf('\nChecking animal health...\n')
                ex = check_health(ex,app,0);
            end
        else
            if time_diff >= minutes(20)
                fprintf('\nChecking animal health...\n')
                ex = check_health(ex,app,0);
            end
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

        %% CREATE BLOCK OF TRIALS
        fprintf('\nCreating trial block...\n')
        ex.counter.iblock = ex.counter.iblock + 1;
        if strcmp(app.DropDown_test_mode.Value, 'Timed')
            ex.counter.grand_iblock = ex.counter.grand_iblock + 1;
        end
        ex = create_new_stimuli_block(ex,app);

        %% DATA COLLECTION
        fprintf('\nPresenting stimulus...\n')
        ex = setup_experiment_present_sound(ex,app); % Present stimuli and measure signals

        %% DATA PRE-PROCESSING
        fprintf('\nPre-processing responses...\n')
        ex = preprocess_signal(ex,app);

        %% DATA ANALYSIS
        if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
            fprintf('\nAnalyzing responses...\n')
            ex = separate_subtract_bootstrap(ex,app);

            %% BOOTSTRAPPING RESULTS
            if ex.decision(ex.counter.iamp).resp_found % When there was a significant response found
                [y, Fs] = audioread('resp_found.mp3');
                sound(y, Fs)
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Response detected';
            end
        end

        %% CHECK IF MAX (VALID) TRIALS PRESENTED OR TIME LIMIT MET
        if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
            if size(ex.kept.trials_filtered,1) >= ex.info.trials.max_trials ... % Valid trials based only on analysis channel
                    && ex.decision(ex.counter.iamp).amp_done == 0 ...
                    && ex.decision(ex.counter.iamp).resp_found == 0
                [y, Fs] = audioread('no_resp.mp3');
                sound(y, Fs)
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus.amplitude_spl;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Maximum trials reached';
            end
        elseif strcmp(app.DropDown_test_mode.Value, 'Static trial count')
            if ex.valid_trials(ex.counter.iamp) >= ex.info.trials.max_trials ... % Valid trials based on all channels
                    && ex.decision(ex.counter.iamp).amp_done == 0 ...
                    && ex.decision(ex.counter.iamp).resp_found == 0
                [y, Fs] = audioread('no_resp.mp3');
                sound(y, Fs)
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus.amplitude_spl;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Maximum trials reached';
            end
        elseif strcmp(app.DropDown_test_mode.Value, 'Timed')
            if datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.info.experiment.amp_time_start >= minutes(ex.info.experiment.timer_dur_min)
                [y, Fs] = audioread('no_resp.mp3');
                sound(y, Fs)
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus.amplitude_spl;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Experiment time reached';
            end
        end
        
        fprintf('\n--- Block Completed (Amp %d, Block %d) ---\n', ex.counter.iamp, ex.counter.iblock);

        %% SAVE RAW DATA
        ex = plan_save_single_raw(ex,app);

        %% CONTINUE TESTING?
        if ex.decision(ex.counter.iamp).amp_done == 1
            if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
                ex = model_response(ex,app);
            end

            if strcmp(app.DropDown_test_mode.Value, 'Adaptive') || strcmp(app.DropDown_test_mode.Value, 'Static trial count')
                ex = make_decision_dialog(ex,app);
            end

            % End experiment?
            if strcmp(app.DropDown_test_mode.Value, 'Adaptive') || strcmp(app.DropDown_test_mode.Value, 'Static trial count')
                if ex.exp_done
                    if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
                        ex = save_session_data(ex, app);
                    end
                    return
                else
                    ex = select_next_dialog(ex);
                end
            elseif strcmp(app.DropDown_test_mode.Value, 'Timed')
                % Do not allow testing at a different amplitude at this time
                % If I do, then I need to restructure some code particularly counters!
                return 
            end
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
end


