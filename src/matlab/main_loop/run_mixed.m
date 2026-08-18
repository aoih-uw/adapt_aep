function ex = run_mixed(app)
%% Main experiment function for presenting stimuli of multiple types (Stimulus ON/OFF AND Trimmed)

% DO YOUR BEST!
fprintf('  \n')
fprintf('                \n')
fprintf('   Do your best!    \n')
fprintf('          \n')
fprintf('   .-*''`    `*-.._.-''/\n')
fprintf(' < o ))     ,       (\n')
fprintf('   `*-._`._(__.--*"`.\\\n')
fprintf('\n')

ex = app.ex;
ex.info.experiment.exp_time_start = datetime('now', 'TimeZone', 'America/Los_Angeles', 'Format', 'yyyyMMdd_HHmmss');
test_schedule = ex.info.mixed.test_schedule;

while ex.counter.ischedule < size(test_schedule,1)

    %% INCREMENT ISCHEDULE
    ex.counter.ischedule = ex.counter.ischedule+1;

    %% CHECK HEALTH
    ex = check_health(ex,app,0);

    %% CHECK TRIAL COUNT
    % Check if we already have enough trials for this stimulus type
    N_trials_needed = ex.info.mixed.test_schedule(ex.counter.ischedule,4);
    cur_stim_id = ex.info.mixed.test_schedule(ex.counter.ischedule,5);

    %% PRESENT TRIALS
    switch ex.info.experiment.exp_type
        case 'Mixed freqs'
            if ex.info.mixed.trial_counter(cur_stim_id) < N_trials_needed
                ex = run_batch(ex, app);
                ex = plot_mixed_trials(ex,app);
            end

            % REPORT PROGRESS
fprintf(' %2.1f%%\n', mean(min(ex.info.mixed.trial_counter(:) ./ ex.info.mixed.uniq_stimuli(:,4), 1)) * 100);
            % SAVE RAW DATA
            if ex.counter.iblock > 0 % Only save if there is data in the block structure
                if ex.counter.iblock >= (ex.info.mixed.N_trials_per_file/ex.info.trials.trials_per_block) || ...
                        ex.counter.ischedule == size(test_schedule,1)
                    ex = save_mixed_raw(ex,app);
                end
            end
    end
end