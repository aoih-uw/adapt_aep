function ex = make_decision_dialog(ex,app)
    [y, Fs] = audioread('step.mp3');
    sound(y, Fs)

    reason = ex.decision(ex.counter.iamp).amp_done_reason;
    
    fprintf('\n========================================\n');
    fprintf('  Make Decision\n');
    fprintf('  Reason: %s\n', reason);
    fprintf('========================================\n');
    fprintf('  [n] New Amplitude\n');
    fprintf('  [e] End Experiment\n');
    fprintf('========================================\n');
    
    choice = '';
    while ~strcmpi(choice, 'n') && ~strcmpi(choice, 'e')
        choice = input('Enter choice (n/e): ', 's');
        if ~strcmpi(choice, 'n') && ~strcmpi(choice, 'e')
            fprintf('Invalid input. Please try again.\n');
        end
    end
    
    ex.decision(ex.counter.iamp).amp_done = 1;
    
    if strcmpi(choice, 'n')
    else
        ex.exp_done = 1;
        fprintf('\nSaving session data...\n');
        ex = save_session_data(ex, app);
    end
end