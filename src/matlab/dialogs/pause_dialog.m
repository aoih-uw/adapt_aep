function [action, ex] = pause_dialog(ex,app)
[y, Fs] = audioread('step.mp3');
sound(y, Fs)
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
            ex = save_raw_data(ex);
            ex.decision(ex.counter.iamp).amp_done = 1;
            ex.decision(ex.counter.iamp).amp_done_reason = 'User override';
            ex = select_next(ex);
            return;
        case 'e'
            action = 'stop';
            ex = save_raw_data(ex);
            fprintf('\nExperiment stopped by user\n');
            ex.decision(ex.counter.iamp).amp_done = 1;
            ex.exp_done = 1;
            ex.decision(ex.counter.iamp).amp_done_reason = 'User override';
            ex = save_session_data(ex, app);
            return;
        otherwise
            fprintf('Invalid choice. Please enter r, c, or e.\n');
    end
end
end