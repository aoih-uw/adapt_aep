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
    %% Increment counters
    ex.counter.iamp = ex.counter.iamp + 1;
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.decision(ex.counter.iamp).amp_done = 0;
    ex.counter.iblock = 0;
    if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
        ex.counter.iboot = 0;
    end
    ex.info.experiment.amp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');

    while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude

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

        %% DATA ANALYSIS
        if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
            fprintf('\nAnalyzing responses...\n')
            ex = separate_subtract_bootstrap(ex,app);

            %% BOOTSTRAPPING RESULTS
            if ex.decision(ex.counter.iamp).resp_found % When there was a significant response found
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Response detected';
            end
        end

        %% CHECK IF MAX (VALID) TRIALS PRESENTED OR TIME LIMIT MET
        if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
            if size(ex.kept.trials_filtered,1) >= ex.info.trials.max_trials ... % Valid trials based only on analysis channel
                    && ex.decision(ex.counter.iamp).amp_done == 0 ...
                    && ex.decision(ex.counter.iamp).resp_found == 0
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus(1).amplitude_spl;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Maximum trials reached';
            end
        elseif strcmp(app.DropDown_test_mode.Value, 'Static trial count')
            if ex.valid_trials(ex.counter.iamp) >= ex.info.trials.max_trials ... % Valid trials based on all channels
                    && ex.decision(ex.counter.iamp).amp_done == 0 ...
                    && ex.decision(ex.counter.iamp).resp_found == 0
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus(1).amplitude_spl;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Maximum trials reached';
            end
        elseif strcmp(app.DropDown_test_mode.Value, 'Timed')
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

    end
end


