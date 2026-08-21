function [kept_trials, kept_jitter] = get_kept_trials(grand_ex_save, iname, isubj, ...
    ibatch, cur_chan, single_batch_locs, mult_batch_locs)

if ismember(ibatch,single_batch_locs)
    % None of the trials got rejected
    kept_trials = grand_ex_save{iname,isubj}.raw_signals(1,ibatch).electrodes_microV(:,:,cur_chan);
    kept_jitter = grand_ex_save{iname,isubj}.block_level_info(1,ibatch).jitter;
    
    % Alert user if trials were rejected in this case
    if length(grand_ex_save{iname,isubj}.block_level_info(ibatch).kept_trials_idx) ~= 10
        keyboard
    end
elseif ismember(ibatch, mult_batch_locs(:,1)) % Only look through first_batches
    % Get multiple attempt data
    [cur_row, ~] = find(mult_batch_locs == ibatch);
    first_batch = mult_batch_locs(cur_row,1);
    last_batch = mult_batch_locs(cur_row,2);

    % Check that all the stim types and amps are the same across the
    % selected batches
    amps = arrayfun(@(b) grand_ex_save{iname,isubj}.block_level_info(b).stim_amp, first_batch:last_batch);
    stim_types = arrayfun(@(b) grand_ex_save{iname,isubj}.block_level_info(b).stim_type, first_batch:last_batch, 'UniformOutput', false);

    if length(unique(amps)) > 1 || length(unique(stim_types)) > 1
        keyboard
    end
    
    % Get largest signal length across similar batches
    sizes = arrayfun(@(b) ...
        size(grand_ex_save{iname,isubj}.raw_signals(1,b).electrodes_microV,2), ...
        first_batch:last_batch);
    max_size = max(sizes);
    n_rows = 10*length(first_batch:last_batch);
    temp_sigs = NaN(n_rows,max_size);
    temp_jitter = NaN(n_rows,1);
    my_idx = 1;

    % Compile like batches into a single matrix
    for iii = first_batch:last_batch
        cur_batch = grand_ex_save{iname,isubj}.raw_signals(1,iii).electrodes_microV(:,:,cur_chan);
        cur_jitter = grand_ex_save{iname,isubj}.block_level_info(1,iii).jitter;
        temp_sigs(my_idx:my_idx+9,1:size(cur_batch,2)) = cur_batch;
        temp_jitter(my_idx:my_idx+9) = cur_jitter;
        my_idx = my_idx + 10;
    end
    % Keep non-rejected trials only
    kept_trials_idx = grand_ex_save{iname,isubj}.block_level_info(1,last_batch).kept_trials_idx;
    kept_trials = temp_sigs(kept_trials_idx,:);
    kept_jitter = temp_jitter(kept_trials_idx,:);
else
    kept_trials = [];
    kept_jitter = [];
end