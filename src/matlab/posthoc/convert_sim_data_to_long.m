%% convert_sim_data_to_long
function sim_results = convert_sim_data_to_long(subjid, cur_freq, amp_vec, it_vec, CI_vec, ...
    resp_found_vec, ~, low_growth, my_chans, my_chans_name)

% Assign variables
sim_results = struct();
n_chans = numel(my_chans);

%% Resp_found heatmap
[Chan, Amp, IT, CI] = ndgrid(1:n_chans,amp_vec, it_vec,CI_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
resp_found = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name),freq_col, Amp(:), ...
    IT(:), CI(:), resp_found_vec(:), 'VariableNames',{'Subj_ID','Chan','Freq', 'Amp','Boot_It_N','CI','Val'});
sim_results.resp_found = resp_found;

% %% 2f growth functions
% % Summary vals
% [Chan, Amp] = ndgrid(1:n_chans, amp_vec);
% subjid_col = repmat(subjid,length(Chan(:)),1);
% freq_col = repmat(cur_freq,length(Chan(:)),1);
% twof_summary = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name), freq_col, Amp(:), ...
%     twof_growth_func.mean(:), twof_growth_func.sem(:), twof_growth_func.noise_floor(:), ...
%     'VariableNames',  {'Subj_ID','Chan','Freq','Amp','Mean','SEM','Noise_Floor'});
% 
% % Fit plots
% X = permute(twof_growth_func.x_vec,[2 3 1]);
% Y = permute(twof_growth_func.y_vec, [2 3 1]);
% [~, Chan] = ndgrid(1:size(X,1),1:n_chans);
% subjid_col = repmat(subjid,length(Chan(:)),1);
% freq_col = repmat(cur_freq,length(Chan(:)),1);
% twof_fit = table(subjid_col, categorical(Chan(:),1:n_chans, my_chans_name),freq_col, X(:), Y(:), ...
%     'VariableNames',{'Subj_ID','Chan','Freq','X','Y'});
% 
% sim_results.twof.summary = twof_summary;
% sim_results.twof.fit = twof_fit;

%% Low CI growth functions
% Summary vals
[Chan, Amp] = ndgrid(1:n_chans, amp_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
lowCI_summary = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name), freq_col, Amp(:), ...
    low_growth.mean(:), low_growth.trials(:), ...
    'VariableNames',  {'Subj_ID','Chan','Freq','Amp','Mean','STD'});

% Threshold
thresh_vec = low_growth.thresh_ci;
chan_col = (1:n_chans)';
subjid_col = repmat(subjid,length(thresh_vec),1);
freq_col = repmat(cur_freq,length(thresh_vec),1);

lowCI_thresh = table(subjid_col, categorical(chan_col,1:n_chans,my_chans_name), ...
    freq_col, thresh_vec, ...
    'VariableNames',  {'Subj_ID','Chan','Freq','Threshold'});

% Fit parameters
p = low_growth.p;
chan_col = (1:n_chans)';
subjid_col = repmat(subjid,length(chan_col),1);
freq_col = repmat(cur_freq,length(chan_col),1);

lowCI_p = table(subjid_col, categorical(chan_col,1:n_chans,my_chans_name), freq_col, ...
    p(:,1), p(:,2), p(:,3), p(:,4), ...
    'VariableNames',{'Subj_ID','Chan','Freq','a','k','x0','b'});

% Fit plots
X = permute(low_growth.x_vec,[2 3 1]);
Y = permute(low_growth.y_vec, [2 3 1]);
[~, Chan] = ndgrid(1:size(X,1),1:n_chans);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
lowCI_fit = table(subjid_col, categorical(Chan(:),1:n_chans, my_chans_name),freq_col, X(:), Y(:), ...
    'VariableNames',{'Subj_ID','Chan','Freq','X','Y'});

% Store in sim_results
sim_results.lowCI.summary = lowCI_summary;
sim_results.lowCI.thresholds = lowCI_thresh;
sim_results.lowCI.p = lowCI_p;
sim_results.lowCI.fit = lowCI_fit;

% % Check
% r = 1 + (2-1)*n_chans;   % channel 1, amplitude 2
% isequaln(sim_results.twof.summary.Mean(r), twof_growth_func.mean(1,2))