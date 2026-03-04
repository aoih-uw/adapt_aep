function ex = make_decision_dialog(ex,app)
    [y, Fs] = audioread('step.mp3');
    sound(y, Fs)

    reason = ex.decision(ex.counter.iamp).amp_done_reason;
    
    fprintf('\n========================================\n');
    fprintf('  Make Decision\n');
    fprintf('  Reason: %s\n', reason);
    fprintf('========================================\n');
    fprintf('  [y] New Amplitude\n');
    fprintf('  [n] End Experiment\n');
    fprintf('========================================\n');
    
    choice = '';
    while ~strcmpi(choice, 'y') && ~strcmpi(choice, 'n')
        choice = input('Enter choice (y/n): ', 's');
        if ~strcmpi(choice, 'y') && ~strcmpi(choice, 'n')
            fprintf('Invalid input. Please try again.\n');
        end
    end
    
    ex.decision(ex.counter.iamp).amp_done = 1;
    
    if strcmpi(choice, 'y')
        fprintf('\nSaving current amplitude data...\n');
        ex = save_raw_data(ex);
    else
        ex.exp_done = 1;
        fprintf('\nSaving session and current amplitude data...\n');
        ex = save_raw_data(ex);
        ex = save_session_data(ex, app);
    end
end