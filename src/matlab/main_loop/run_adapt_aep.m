function ex = run_adapt_aep(app)
%% function main_loop %%

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

% try
while ~ex.exp_done % While testing current stimulus frequency
    ex.counter.iamp = ex.counter.iamp + 1;
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.decision(ex.counter.iamp).amp_done = 0;
    ex.counter.iblock = 0;
    ex.counter.iboot = 0;
    ex.info.experiment.amp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');

    %% UPDATE GUI
    app.Label_current_amp.Text = string(ex.info.stimulus.amplitude_spl);

    while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude

        tic()
        %% CREATE BLOCK OF TRIALS
        fprintf('\nCreating trial block...\n')
        ex = create_new_stimuli_block(ex,app);

        %% READ THERMOMETER
        fprintf('\nChecking temperature...\n')
        % ex = check_temperature(ex);

        %% DATA COLLECTION
        fprintf('\nPresenting stimulus...\n')
        ex = setup_experiment_present_sound(ex,app); % Present stimuli and measure signals

        fprintf('\nResponses measured...\n')

        %% DATA PRE-PROCESSING
        fprintf('\nPre-processing responses...\n')
        ex = preprocess_signal(ex,app);

        if ex.no_valid_trials
            continue
        end

        %% DATA ANALYSIS
        if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
            fprintf('\nAnalyzing responses...\n')
            ex = separate_subtract_bootstrap(ex,app);

            %% CHECK IF FINISHED TESTING THIS AMPLITUDE
            if ex.decision(ex.counter.iamp).resp_found % When there was a significant response found
                [y, Fs] = audioread('resp_found.mp3');
                sound(y, Fs)
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Response detected';
            end
        end

        %% CHECK IF MAX (VALID) TRIALS PRESENTED OR TIME LIMIT MET
        if strcmp(app.DropDown_test_mode.Value, 'Adaptive') || strcmp(app.DropDown_test_mode.Value, 'Static trial count')
            if ex.valid_trials(ex.counter.iamp) >= ex.info.adaptive.max_trials ...
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

        %% Save raw data
        ex = autosave_data(ex,app);

        %% HEALTH CHECK
        if ex.counter.ihealth == 0
            fprintf('\nChecking animal health...\n')
            ex = check_health(ex,app,0);
        else
            time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.health(ex.counter.ihealth).time_stamp;
            if strcmp(app.DropDown_test_mode.Value, 'Timed')
                if time_diff >= minutes(1)
                    fprintf('\nChecking animal health...\n')
                    ex = check_health(ex,app,0);
                end
            else
                if time_diff >= minutes(10)
                    fprintf('\nChecking animal health...\n')
                    ex = check_health(ex,app,0);
                end
            end
        end

        %% Are we done testing at this frequency?
        if ex.decision(ex.counter.iamp).amp_done == 1
            % Adaptive: Save raw file and model response
            if strcmp(app.DropDown_test_mode.Value, 'Adaptive') 
                ex = save_raw_data(ex, app, false);
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


% catch ME
%     [y, Fs] = audioread('error.mp3');
%     sound(y, Fs)
%     fprintf('\nExperiment error: %s\n', ME.message)
%     ex = save_raw_data(ex,app);
%     % ex = save_session_data(ex, app); %#%#%#
%     rethrow(ME)
% end

