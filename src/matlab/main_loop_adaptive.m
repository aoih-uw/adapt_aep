function ex = main_loop_adaptive(app) %# add a main_loop_manual
addpath(genpath("\\wsl$\ubuntu\home\aoih\adapt_aep\src\matlab"))

%% function main_loop %%

%   .-*'`    `*-.._.-'/
% < * ))     ,       (
%   `*-._`._(__.--*"`.\

%% SETUP
try
    ex = app.ex;
    app.ex = [];  % Set to empty
    addpath(genpath('matlab'))
    ex = setup(ex);
catch ME
    fprintf('Experiment setup error: %s\n', ME.message)
    rethrow(ME)
end

%% MAIN LOOP
ex.counter.iamp = 0; % Amplitude counter
try
    while ~ex.decision.exp_done % While testing current stimulus frequency
        % UPDATE COUNTERS
        ex.counter.iamp = ex.counter.iamp + 1;
        ex.decision(ex.counter.iamp).amp_done = 0;
        ex.counter.iblock = 0;

        % CREATE BLOCK OF TRIALS
        ex = make_stim_block(ex);

        while ~ex.decision(ex.counter.iamp).amp_done % While testing current stimulus amplitude
            
            ex.counter.iblock = ex.counter.iblock + 1; % Iterate block number

            % HEALTH CHECK
            if ex.counter.iblock == 1 && ex.counter.iamp == 1 % First tested amplitude and block
                ex.health(end).time_stamp = datetime('now');
            end
            time_diff = datetime('now') - ex.health(end).time_stamp;
            if time_diff >= minutes(15)
                ex = check_health(app,ex);
                if ex.decision.exp_done == 1 % Did user decide to stop testing due to bad health?
                    save_data(ex)
                    ex = end_experiment(ex);
                    return
                end
            end

            % DATA COLLECTION
            ex = present_and_measure(ex); % Present stimuli and measure signals

            % UPDATE MONITOR GUI
            try
                ex = update_monitor_GUI(ex,app); %# Plot average and +/- 1 std downsampled raw signals (hydrophone and channel signals) in block
            catch
                warning('Main GUI update failed')
            end

            % DATA PROCESSING
            ex = preprocess_signal(ex);
            ex = analyze_signal(ex); % Analyze electrode signal
            ex = is_response_present(ex); % Is a response present? here ex.decision().amp_done and amp_done_reason will be assigned

            % UPDATE SUMMARY GUI
            try
                ex = update_summary_GUI(ex,app); %# include plot where model panel has points with # of trials scaling the point size
            catch
                warning('Main GUI update failed')
            end

            % CHECK IF FINISHED TESTING THIS AMPLITUDE
            if ex.decision(ex.counter.iamp).amp_done % When there was a significant response found
                save_data(ex)
                ex = select_next(ex); % decide next amplitude to test for or end experiment
            end

            % CHECK IF MAX TRIALS PRESENTED
            trials_presented = ex.counter.iblock*ex.info.adaptive.trials_per_block;
            if trials_presented >= ex.info.adaptive.max_trials && ex.decision(ex.counter.iamp).amp_done == 0
                ex.decision(ex.counter.iamp).amp_done = 1;
                ex.decision.amp_done_reason = 'Maximum trials reached';
                fprintf('Maximum trial number reached. Select next amplitude')
                ex = select_next(ex); %# select next must also allow option to end experiment
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

    ex = end_experiment(ex); %# input ex.decision.exp_done_reason, ex.decision.threshold_spl value here (threshold = smallest dB stimulus that elicited a true response)

catch ME
    fprintf('Experiment error: %s\n', ME.message)
    save_data(ex)
    rethrow(ME)
end

