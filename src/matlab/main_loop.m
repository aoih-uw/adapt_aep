function ex = main_loop(app)
%% function main_loop %%

%   .-*'`    `*-.._.-'/
% < * ))     ,       (
%   `*-._`._(__.--*"`.\

%% Setup
try
    addpath(genpath('matlab'))
    ex = setup();
catch ME
    fprintf('Experiment setup error: %s\n', ME.message)
    rethrow(ME)
end

%% Main experiment loop
try
    while ~ex.trial.exp_done % While testing current stimulus frequency
        ex = select_next(ex); % Select amplitude to test
        ex.block.iteration_num = 0;
        
        % Update GUI
        try
            ex = update_GUI(ex,app);
        catch
            warning('GUI update failed')
        end

        while ~ex.trial.amp_done % While testing current stimulus amplitude
            % Data collection
            ex = make_stim_block(ex); % Create block of stimuli
            ex = present_and_measure(ex); % Present stimuli and measure signals
            ex.block.iteration_num = ex.block.iteration_num + 1; % Iterate block number

            % Plot all downsampled raw signals (hydrophone and channel signals) in block
            try
                ex = update_main_GUI(ex);
            catch
                warning('Main GUI update failed')
            end
            
            % Data processing
            ex = preprocess_signal(ex);
            ex = analyze_signal(ex); % Analyze electrode signal
            ex = make_decision(ex); % Is a response present?

            % Inspect analysis results
            try
                ex = inspect_analysis_GUI(ex); % at this point make decision of ex.trial.amp_done in the GUI
            catch
                warning('Analysis result GUI error')
            end
            
            % Update GUI Summary Plots
            try
                ex = update_main_GUI(ex);
            catch
                warning('Main GUI update failed')
            end

            % Check if max block count met
            trials_presented = ex.block.iteration_num*ex.info.adaptive.trials_per_block;
            
            if trials_presented >= ex.info.adaptive.max_trials % Maximum trials reached
                ex.trial.amp_done = 1;
                fprintf('Maximum trial number reached. Select new amplitude or conclude test')
            end

            if ex.trial.amp_done
                save_data(ex)
                ex = select_next_GUI(ex);
            else
                ex = select_next_GUI(ex);
            end
        end
        ex = prepare_next_amp(ex);
    end

    % Add data to csv that shows threshold data for all other frequencies
    % tested
    ex = finish_experiment(ex);
catch ME
    fprintf('Experiment error: %s\n', ME.message)
    save_data(ex)
    rethrow(ME)
end

