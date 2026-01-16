function ex = main_loop_adaptive(app) %# add a main_loop_manual
addpath(genpath("\\wsl$\ubuntu\home\aoih\adapt_aep\src\matlab"))

%% function main_loop %%

%   .-*'`    `*-.._.-'/
% < * ))     ,       (
%   `*-._`._(__.--*"`.\

%% Setup
try
    ex = app.ex;
    app.ex = [];  % Set to empty
    addpath(genpath('matlab'))
    ex = setup(ex);
catch ME
    fprintf('Experiment setup error: %s\n', ME.message)
    rethrow(ME)
end

%% Main experiment loop
ex.counter.iamp = 0; % Amplitude counter
try
    while ~ex.trial.exp_done % While testing current stimulus frequency
        % Check for stop
        if app.StopFlag
            save_data(ex)
            fprintf('Experiment stopped by user\n')
            return
        end

        % Update counters
        ex.counter.iamp = ex.counter.iamp + 1;
        ex.counter(ex.counter.iamp).iblock = 0;

        % Create block of trials
        ex = make_stim_block(ex);

        while ~ex.trial.amp_done % While testing current stimulus amplitude
            % Check for pause
            while app.PauseFlag
                pause(0.1)
                drawnow
            end

            % Check for stop
            if app.StopFlag
                save_data(ex)
                fprintf('Experiment stopped by user\n')
                return
            end


            % Check health if last check happend > 15 minutes ago
            if ex.raw(end).time_stamp - ex.health(end).time_stamp >= 15
                ex = check_health(app,ex); % check if response amplitude has decreased by more than 1/2
                if strcmp(ex.health(end).status, 'bad')
                    % decide whether to continue testing or save and end
                    ex = ask_user_health(ex);
                    if ex.health(end).end_test % User decided to end experiment
                        save_data(ex)
                        return
                    end
                end
            end


            % Data collection
            ex = present_and_measure(ex); % Present stimuli and measure signals
            ex.counter.iblock = ex.counter.iblock + 1; % Iterate block number

            % Plot average and +/- 1 std downsampled raw signals (hydrophone and channel signals) in block
            try
                ex = update_monitor_GUI(ex,app);
            catch
                warning('Main GUI update failed')
            end

            % Data processing
            ex = preprocess_signal(ex);
            ex = analyze_signal(ex); % Analyze electrode signal
            ex = is_response_present(ex); % Is a response present? 

            % Update GUI Summary Plots
            try
                ex = update_summary_GUI(ex,app); %# include plot where model panel has points with # of trials scaling the point size
            catch
                warning('Main GUI update failed')
            end

            % Check if max block count met
            trials_presented = ex.counter.iblock*ex.info.adaptive.trials_per_block;

            if trials_presented >= ex.info.adaptive.max_trials % Maximum trials reached, end experiment
                ex.decision.amp_done = 1;
                fprintf('Maximum trial number reached. Select next amplitude')
                ex = select_next(ex);
                return
            end

            if ex.decision.amp_done % If done testing at this amplitude
                save_data(ex)
                ex = is_threshold_stable(ex);
                if ex.decision.threshold_done % If threshold estimate is stable
                    % Add data to csv that shows threshold data for all other frequencies
                    % tested
                    % finish experiment/testing at this amplitude
                    ex = finish_experiment(ex);
                    return
                end
            end
        end
        ex = select_next(ex);
        ex = prepare_next_amp(ex); % do calculation of total trials tested etc. here
    end

catch ME
    fprintf('Experiment error: %s\n', ME.message)
    save_data(ex)
    rethrow(ME)
end

