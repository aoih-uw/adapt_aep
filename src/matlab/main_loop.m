function ex = run_adapt_aep(gui_args,app)
%% function main_loop %%

%   .-*'`    `*-.._.-'/
% < * ))     ,       (
%   `*-._`._(__.--*"`.\

%% Setup
try
    addpath(genpath('matlab'))
    ex = setup(gui_args);
catch ME
    fprintf('Experiment setup error: %s\n', ME.message)
    rethrow(ME)
end

%% Main experiment loop
try
    while ~ex.trial.exp_done % While testing current stimulus frequency
        ex = select_next(ex); % Select amplitude to test

        % Update GUI
        try
            ex = update_GUI(ex,app);
        catch
            warning('GUI update failed')
        end

        while ~ex.trial.amp_done % While testing current stimulus amplitude
            % Check if max block count met
            ex = check_max_count(ex);
            if ex.trial.amp_done
                break
            end

            % Data collection
            ex = make_stim_block(ex); % Create block of stimuli
            ex = present_and_measure(ex); % Present stimuli and measure signals
                % Note: use single precision for large arrays
            ex = preprocess_signal(ex);
            ex = analyze_signal(ex); % Analyze electrode signal

            % Update GUI
            try
                ex = update_GUI(ex);
            catch
                warning('GUI update failed')
            end

            ex = make_decision(ex); % Is a response present?

            if ex.trial.amp_done
                save_data(ex)
                ex = select_next(ex);
            else
                ex = select_next(ex);
            end
        end
    end
    % Add data to csv that shows threshold data for all other frequencies
    % tested
    ex = finish_experiment(ex);
catch ME
    fprintf('Experiment error: %s\n', ME.message)
    save_data(ex)
    rethrow(ME)
end

