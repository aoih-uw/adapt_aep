function [all_trials, all_phases,all_jitter] = ...
    collapse_raw_data(all_trials, all_phases,all_jitter, iblock, first_block, ...
    trials_per_block, valid_channels, ex)
%% Collapse raw data across batches for artefact rejection
% Populate matrices
row_idx = 1;
for ii = first_block:iblock
    cur_block = ex.raw(ii).electrodes_microV;
    cur_phase = ex.block(ii).phase_vec;
    cur_jitter = ex.block(ii).jitter;
    n_samples = size(cur_block, 2);
    
    % The first channel is excluded because it is the EKG channel
    for ichan = 1:length(valid_channels) 
        cur_chan = valid_channels(ichan);
        temp = cur_block(:,:,cur_chan);
        all_trials(row_idx:row_idx+trials_per_block-1, 1:n_samples, ichan) = temp;
    end
    all_phases(row_idx:row_idx+trials_per_block-1) = cur_phase;
    all_jitter(row_idx:row_idx+trials_per_block-1) = cur_jitter;
    row_idx = row_idx + trials_per_block;
end

% all_trials (n_trials, n_samples, n_chan) collapse n_trials across all  batches