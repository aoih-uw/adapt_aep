function ex = run_adapt_aep(app)
addpath(genpath("\\wsl$\ubuntu\home\aoih\adapt_aep\src\matlab"))

%% function main_loop %%

%   .-*'`    `*-.._.-'/
% < * ))     ,       (
%   `*-._`._(__.--*"`.\

ex.counter.iamp = 0; % Amplitude counter
try
    while ~ex.decision.exp_done % While testing current stimulus frequency
        % UPDATE COUNTERS
        ex.counter.iamp = ex.counter.iamp + 1;
        ex.decision(ex.counter.iamp).amp_done = 0;
        ex.counter.iblock = 0;

        while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude
            
            % CREATE BLOCK OF TRIALS
            fprintf('Creating trial block...')
            ex = make_stim_block(ex);

            ex.counter.iblock = ex.counter.iblock + 1; % Iterate block number

            % READ THERMOMETER
            fprintf('Checking temperature...')
            ex = check_temperature(ex);

            % HEALTH CHECK
            time_diff = datetime('now') - ex.health(end).time_stamp;
            if time_diff >= minutes(15)
                fprintf('Checking animal health...')
                ex = check_health(app,ex);
                if ex.decision.exp_done == 1 % Did user decide to stop testing due to bad health?
                    save_data(ex)
                    ex = end_experiment(ex);
                    return
                end
            end

            % DATA COLLECTION
            fprintf('Presenting stimulus...')
            ex = present_and_measure(ex); % Present stimuli and measure signals
            fprintf('Responses measured...')
            
            % UPDATE MONITOR GUI
            try
                ex = update_monitor_GUI(ex,app); %# Also add the status values here, Plot average and +/- 1 std downsampled raw signals (hydrophone and channel signals) in block
            catch
                warning('Monitor GUI update failed')
            end

            % DATA PRE-PROCESSING
            fprintf('Pre-processing responses...')
            ex = preprocess_signal(ex);
            
            % DATA ANALYSIS
            trials_presented = ex.counter.iblock*ex.info.adaptive.trials_per_block;
            if trials_presented >= ex.info.adaptive.min_trials_needed_for_analysis % Only conduct analysis once min # of trials reached
                fprintf('Analyzing responses...')
                ex = analyze_signal(ex); % Analyze electrode signal, assign resp_found here
            end

            % UPDATE SUMMARY GUI
            try
                ex = update_summary_GUI(ex,app); %# include plot where model panel has points with # of trials scaling the point size
            catch
                warning('Summary GUI update failed')
            end

            % CHECK IF FINISHED TESTING THIS AMPLITUDE
            if ex.decision(ex.counter.iamp).resp_found % When there was a significant response found
                % Decide to move onto next amplitude or collect another
                % block
                ex = resp_found_dialog(ex);
                if ex.decision(ex.counter.iamp).amp_done
                    save_data(ex)
                    ex = select_next_dialog(ex); % decide next amplitude to test for or end experiment
                elseif ex.decision.exp_done == 1
                    save_data(ex)
                    ex = end_experiment(ex);
                    return
                end
            end

            % CHECK IF MAX TRIALS PRESENTED
            if trials_presented >= ex.info.adaptive.max_trials && ex.decision(ex.counter.iamp).amp_done == 0
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision(ex.counter.iamp).amp_done_reason = 'Maximum trials reached';
                ex = select_next_dialog(ex); %# select next must also allow option to end experiment
                if ex.decision.exp_done == 1
                    ex.decision.exp_done_reason = 'Maximum trials reached. User terminated experiment';
                    save_data(ex)
                    ex = end_experiment(ex);
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
        end
    end

catch ME
    fprintf('Experiment error: %s\n', ME.message)
    save_data(ex)
    rethrow(ME)
end

