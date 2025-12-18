%% function main_loop %%
%% Setup
try
    ex = setup_exp;
catch ME
    fprintf('Experiment setup error: %s\n', ME.message)
    shutdown_hardware(ex)
    rethrow(ME)
end

%% Main experiment loop
try
    while ~ex.trial.exp_done % While testing current stimulus frequency
        ex = select_amp(ex); % Select amplitude to test

        % Update GUI
        try
            ex = update_GUI(ex);
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
            ex = analyze_signal(ex); % Analyze electrode signal

            % Update GUI
            try
                ex = update_GUI(ex);
            catch
                warning('GUI update failed')
            end

            ex = make_decision(ex); % Is a response present?
        end
        save_data(ex)
    end
catch ME
    fprintf('Experiment error: %s\n', ME.message)
    save_data(ex)
    rethrow(ME)
end

