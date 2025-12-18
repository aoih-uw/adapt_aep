function ex = check_max_count(ex)
ex.trial.block_count = ex.trial.block_count + 1;
if ex.trial.block_count > ex.params.maxBlocks
    fprintf('Max blocks (%d) reached for amplitude %d', ...
        ex.params.maxBlocks, ex.trial.amp_idx);
    ex.trial.amp_done = true;
end