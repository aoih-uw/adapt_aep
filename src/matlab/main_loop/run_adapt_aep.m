function ex = run_adapt_aep(app)

%% function main_loop %%

fprintf('   .-*''`    `*-.._.-''/\n')
fprintf(' < * ))     ,       (\n')
fprintf('   `*-._`._(__.--*"`.\\\n')

ex = app.ex;
ex.info.experiment.exp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
ex = select_next_dialog(ex);

% try
while ~ex.exp_done % While testing current stimulus frequency
    ex.counter.iamp = ex.counter.iamp + 1;
    ex.decision(ex.counter.iamp).resp_found = 0;
    ex.decision(ex.counter.iamp).amp_done = 0;
    ex.counter.iblock = 0;

    % UPDATE GUI
    app.Label_current_amp.Text = string(ex.info.stimulus.amplitude_spl);

    while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude

        % CREATE BLOCK OF TRIALS
        fprintf('\nCreating trial block...\n')
        ex = stim_block_creation(ex);

        % READ THERMOMETER
        fprintf('\nChecking temperature...\n')
        % ex = check_temperature(ex);

        % HEALTH CHECK
        time_diff = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss') - ex.health(ex.counter.health).time_stamp;
        if time_diff >= minutes(15)
            fprintf('\nChecking animal health...\n')
            ex = check_health(ex,app);
            if ex.exp_done == 1 % Did user decide to stop testing due to bad health?
                ex = save_raw_data(ex);
                ex = save_session_data(ex, app);
                return
            end
        end

        % DATA COLLECTION
        fprintf('\nPresenting stimulus...\n')
        ex = present_and_measure(ex,app); % Present stimuli and measure signals

        fprintf('\nResponses measured...\n')

        % DATA PRE-PROCESSING
        fprintf('\nPre-processing responses...\n')
        ex = preprocess_signal(ex,app);

        % DATA ANALYSIS
        fprintf('\nAnalyzing responses...\n')
        ex = separate_subtract_bootstrap(ex,app);

        % AUTOSAVE
        ex = autosave_data(ex,app);

        % CHECK IF FINISHED TESTING THIS AMPLITUDE
        if ex.decision(ex.counter.iamp).resp_found % When there was a significant response found
            [y, Fs] = audioread('resp_found.mp3');
            sound(y, Fs)
            ex = model_response(ex,app);
            % Tell user that a response was found
            ex.decision(ex.counter.iamp).amp_done_reason = 'Response detected';
            fprintf('\nSaving current amplitude data...\n');
            ex = save_raw_data(ex);
            ex = make_decision_dialog(ex,app);

            % Finish experiment
            if ex.exp_done
                return
            end

            % Test next amplitude
            if ex.decision(ex.counter.iamp).amp_done
                ex = select_next_dialog(ex);
            end
           
        end


        % CHECK IF MAX TRIALS PRESENTED
        if ex.trial_count(ex.counter.iamp) >= ex.info.adaptive.max_trials ...
                && ex.decision(ex.counter.iamp).amp_done == 0 ...
                && ex.decision(ex.counter.iamp).resp_found == 0
            [y, Fs] = audioread('no_resp.mp3');
            sound(y, Fs)

            ex.decision(ex.counter.iamp).amp_done = 1;
            ex.decision(ex.counter.iamp).amp_done_reason = 'Maximum trials reached';

            % Add collected temporary data officially to the model
            ex.model.doub_freq_diff_vec = [ex.model.doub_freq_diff_vec {ex.model.doub_freq_diff_vec_temp}]; % (trials x stimulus amplitude)
            ex.model.doub_freq_dur_vec = [ex.model.doub_freq_dur_vec {ex.model.doub_freq_dur_vec_temp}]; % (trials x stimulus amplitude)
            ex.model.noise_floor = [ex.model.noise_floor {ex.model.noise_floor_temp}]; % (trials x stimulus amplitude)
            ex.model.amplitude_vec = [ex.model.amplitude_vec ex.info.stimulus.amplitude_spl]; % (1 x N_tested_amplitudes)
            ex = model_response(ex,app);

            % Select next amplitude to test
            fprintf('\nSaving current amplitude data...\n');
            ex = save_raw_data(ex);
            ex = make_decision_dialog(ex,app);

            % Finish experiment
            if ex.exp_done
                return
            end

            % Test next amplitude
            if ex.decision(ex.counter.iamp).amp_done
                ex = select_next_dialog(ex);
            end
            
        end

        % CHECK FOR PAUSE
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

        % See if we wanted to end the experiment yet
        if ex.exp_done
            fprintf('\nSaving session and current amplitude data...\n');
            ex = save_raw_data(ex);
            ex = save_session_data(ex, app);
            return
        end
    end
end
end


% catch ME
% [y, Fs] = audioread('error.mp3');
% sound(y, Fs)
%     fprintf('\nExperiment error: %s\n', ME.message)
%     ex = save_raw_data(ex);
%     ex = save_session_data(ex, app);
%     rethrow(ME)
% end

