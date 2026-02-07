function ex = run_adapt_aep(app)
addpath(genpath("\\wsl$\ubuntu\home\aoih\adapt_aep\src\matlab"))

%% function main_loop %%

%   .-*'`    `*-.._.-'/
% < * ))     ,       (
%   `*-._`._(__.--*"`.\

ex.counter.iamp = 0; % Amplitude counter
ex.info.exp_time_start = date_time('now');

try
    while ~ex.exp_done % While testing current stimulus frequency
        ex.counter.iamp = ex.counter.iamp + 1;
        ex.decision(ex.counter.iamp).resp_found = 0;
        ex.decision(ex.counter.iamp).amp_done = 0;
        ex.counter.iblock = 0;

        % UPDATE GUI
        app.Label_current_amp.Text = string(ex.info.stimulus.amplitude_spl);

        while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude

            % CREATE BLOCK OF TRIALS
            fprintf('Creating trial block...')
            ex = make_stim_block(ex);

            ex.counter.iblock = ex.counter.iblock + 1; % Iterate block number

            % READ THERMOMETER
            fprintf('\nChecking temperature...')
            ex = check_temperature(ex);

            % HEALTH CHECK
            time_diff = datetime('now') - ex.health(end).time_stamp;
            if time_diff >= minutes(15)
                fprintf('\nChecking animal health...')
                ex = check_health(app,ex);
                if ex.exp_done == 1 % Did user decide to stop testing due to bad health?
                    ex = save_raw_data(ex);
                    ex = save_session_data(ex);
                    return
                end
            end

            % DATA COLLECTION
            fprintf('\nPresenting stimulus...')
            ex = present_and_measure(ex,app); % Present stimuli and measure signals
            fprintf('\nResponses measured...')

            % DATA PRE-PROCESSING
            fprintf('\nPre-processing responses...')
            ex = preprocess_signal(ex,app);

            % DATA ANALYSIS
            trials_presented = ex.block(iblock).N_trials_presented;
            if trials_presented >= ex.info.adaptive.min_trials_needed_for_analysis % Only conduct analysis once min # of trials reached
                fprintf('\nAnalyzing responses...')
                ex = separate_subtract_bootstrap(ex,app);
            end

            % CHECK IF FINISHED TESTING THIS AMPLITUDE
            if ex.decision(ex.counter.iamp).resp_found % When there was a significant response found
                if iamp > 3  % Model the response once we have 3 data points
                    ex = model_response(ex,app);
                end
                % Tell user that a response was found
                ex = resp_found_dialog(ex);
                if ex.decision(ex.counter.iamp).amp_done
                    ex = save_raw_data(ex);
                    ex = select_next_dialog(ex); % decide next amplitude to test for or end experiment
                elseif ex.exp_done == 1
                    ex = save_raw_data(ex);
                    ex = save_session_data(ex);
                    return
                end
            end

            % CHECK IF MAX TRIALS PRESENTED
            if trials_presented >= ex.info.adaptive.max_trials && ex.decision(ex.counter.iamp).amp_done == 0
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Maximum trials reached';

                % Add collected temporary data officially to the model
                ex.model.doub_freq_resp_mV = [ex.model.doub_freq_resp_mV {ex.model.doub_freq_resp_mV_temp}];
                ex.model.noise_floor = [ex.model.noise_floor {ex.model.noise_floor_temp}];
                ex.model.amplitude_vec = [ex.model.amplitude_vec ex.info.stimulus.amplitude_spl];
                ex = model_response(ex,app);

                % Select next amplitude to test
                ex = select_next_dialog(ex);

                if ex.exp_done == 1 % If user decided to end experiment
                    ex = save_raw_data(ex);
                    ex = save_session_data(ex);
                    return
                end
            end

            % CHECK FOR PAUSE
            if app.PauseFlag
                [action, ex] = pause_dialog(ex);
                app.PauseFlag = false;  % Reset pause flag
                if strcmp(action, 'stop')
                    return
                elseif strcmp(action, 'change')
                    continue
                end
                % If 'continue', proceed normally
            end

            % UPDATE GUI
            time_since_exp_start = date_time('now') - ex.info.exp_time_start;
            app.Label_time_elapsed.Text = string(time_since_exp_start, 'hh:mm:ss');
            
            grand_total_N_trials = sum(arrayfun(@(x) x(end), ex.trial_count));
            app.Label_grand_total.Text = string(grand_total_N_trials);
        end
    end

catch ME
    fprintf('Experiment error: %s\n', ME.message)
    ex = save_raw_data(ex);
    ex = save_session_data(ex);
    rethrow(ME)
end

