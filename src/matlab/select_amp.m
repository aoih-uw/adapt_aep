function ex = select_amp(ex)
% GUI pop up to select next stimulus amplitude

% Reset block counter
ex.trial.block_count = 0;
ex.trial.amp_done = false;