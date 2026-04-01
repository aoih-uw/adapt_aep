function ex = health_dialog(ex)
    status = ex.health(1).status;
    if strcmp(status, 'poor')
        [y, Fs] = audioread('error.mp3');
        sound(y, Fs)
        fprintf('\n========================================\n');
        fprintf('  %s  Health Warning\n', char(9888));
        fprintf('  Animal health status: %s\n', upper(status));
        fprintf('========================================\n');
        fprintf('  [y] Continue Testing\n');
        fprintf('  [n] End Experiment\n');
        fprintf('========================================\n');
        
        choice = input('Continue testing? (y/n): ', 's');

        if strcmpi(choice, 'n')
            ex.exp_done = 1;
            ex.decision(ex.counter.iamp).amp_done = 1;
            ex.decision(ex.counter.iamp).amp_done_reason = 'Poor health';
        end
    end
end