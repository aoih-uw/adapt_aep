function ex = run_batch(ex, app)
batch_completed = 0;
while ~batch_completed
    %% CREATE BLOCK OF TRIALS
    ex.counter.iblock = ex.counter.iblock + 1; % iblock resets after every saved batch of data
    ex.counter.grand_iblock = ex.counter.grand_iblock + 1; % grand_iblock never resets
    ex = create_new_stimuli_block(ex,app);

    %% DATA COLLECTION
    ex = setup_experiment_present_sound(ex,app); % Present stimuli and measure signals

    %% REJECT ARTEFACTS
    switch ex.info.experiment.exp_type
        case 'Mixed freqs'
            ex = reject_artefacts_mixed(ex,app);
    end

    %% CHECK TRIAL COUNT
    if ex.counter.N_not_enough_trials > 0
        fprintf('Insufficient valid trials: Reattempting %d\n', ex.counter.N_not_enough_trials)
    elseif ex.counter.N_not_enough_trials == 0
        batch_completed = 1;
    end
end
