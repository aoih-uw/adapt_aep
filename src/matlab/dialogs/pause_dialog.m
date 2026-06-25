function [action, ex] = pause_dialog(ex,app)
[y, Fs] = audioread('user_input.mp3'); sound(y, Fs);

fprintf('\n========================================\n');
fprintf('  Experiment Paused\n');
fprintf('========================================\n');
fprintf('  [r] Resume Testing\n');
fprintf('  [c] Change Amplitude\n');
fprintf('  [e] End Experiment\n');
fprintf('========================================\n');

while true
    choice = input('Enter choice (r/c/e): ', 's');
    switch lower(choice)
        case 'r'
            action = 'continue';
            return;
        case 'c'
            action = 'change';
            ex = save_single_raw(ex, app, false);
            ex.decision(ex.counter.iamp).amp_done = 1;
            ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus.amplitude_spl;
            ex.decision(ex.counter.iamp).amp_done_reason = 'User override';
            ex = select_next_dialog(ex);
            return;
        case 'e'
            action = 'stop';
            ex = save_single_raw(ex,app,false);
            fprintf('\nExperiment stopped by user\n');
            ex.decision(ex.counter.iamp).amp_done = 1;
            ex.decision(ex.counter.iamp).current_amplitude = ex.info.stimulus.amplitude_spl;
            ex.exp_done = 1;
            ex.decision(ex.counter.iamp).amp_done_reason = 'User override';
            
            if strcmp(app.DropDown_test_mode.Value, 'Adaptive')
                ex = save_session_data(ex, app);
            end
            return;
        otherwise
            fprintf('Invalid choice. Please enter r, c, or e.\n');
    end
end
end