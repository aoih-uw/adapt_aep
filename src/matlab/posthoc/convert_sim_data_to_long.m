%% convert_sim_data_to_long
function sim_results = convert_sim_data_to_long(subjid, cur_freq, amp_vec, it_vec, CI_vec, ...
    resp_stable, resp_first, twof_growth, low_growth,  fit_quality_2f, fit_quality_low, ...
    my_chans, my_chans_name)

% Assign variables
sim_results = struct();
n_chans = numel(my_chans);

%% Resp_found heatmap
[Chan, Amp, IT, CI] = ndgrid(1:n_chans,amp_vec, it_vec,CI_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
resp_found = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name),freq_col, Amp(:), ...
    IT(:), CI(:), resp_stable(:), resp_first(:), 'VariableNames',{'Subj_ID','Chan','Freq', 'Amp','Boot_It_N','CI','Stable','First'});
sim_results.resp_found = resp_found;

%% 2f growth functions
% Summary vals
[Chan, Amp] = ndgrid(1:n_chans, amp_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
twof_summary = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name), freq_col, Amp(:), ...
    twof_growth.mean(:), twof_growth.sem(:), twof_growth.noise_floor(:), ...
    'VariableNames',  {'Subj_ID','Chan','Freq','Amp','Mean','SEM','Noise_Floor'});

% Fit plots
X = permute(twof_growth.x_vec,[2 3 1]);
Y = permute(twof_growth.y_vec, [2 3 1]);
[~, Chan] = ndgrid(1:size(X,1),1:n_chans);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
twof_fit = table(subjid_col, categorical(Chan(:),1:n_chans, my_chans_name),freq_col, X(:), Y(:), ...
    'VariableNames',{'Subj_ID','Chan','Freq','X','Y'});

% Store variables
sim_results.twof.summary = twof_summary;

%% Low CI growth functions
%% now low_growth.all vs. low_growth.sim
% Summary vals
[Chan, Amp] = ndgrid(1:n_chans, amp_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
lowCI_summary = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name), freq_col, Amp(:), ...
    low_growth.all.mean(:), low_growth.sim.mean(:), ...
    'VariableNames',  {'Subj_ID','Chan','Freq','Amp','All','Sim'});

% Threshold
thresh_vec = low_growth.all.thresh_ci;
thresh_vec_sim = low_growth.sim.thresh_ci;
chan_col = (1:n_chans)';
subjid_col = repmat(subjid,length(thresh_vec),1);
freq_col = repmat(cur_freq,length(thresh_vec),1);

lowCI_thresh = table(subjid_col, categorical(chan_col,1:n_chans,my_chans_name), ...
    freq_col, thresh_vec, thresh_vec_sim, ...
    'VariableNames',  {'Subj_ID','Chan','Freq','All', 'Sim'});

% Fit parameters
p = low_growth.all.p;
p_sim = low_growth.sim.p;
chan_col = (1:n_chans)';
subjid_col = repmat(subjid,length(chan_col),1);
freq_col = repmat(cur_freq,length(chan_col),1);

lowCI_p = table(subjid_col, categorical(chan_col,1:n_chans,my_chans_name), freq_col, ...
    p(:,1), p(:,2), p(:,3), p(:,4), ...
    p_sim(:,1), p_sim(:,2), p_sim(:,3), p_sim(:,4), ...
    'VariableNames',{'Subj_ID','Chan','Freq',...
    'a_All','k_All','x0_All','b_All', ...
    'a_Sim','k_Sim','x0_Sim','b_Sim'});

% Store in sim_results
sim_results.lowCI.summary = lowCI_summary;
sim_results.lowCI.thresholds = lowCI_thresh;
sim_results.lowCI.p = lowCI_p;
sim_results.lowCI.fit_q = make_fit_qual(subjid, cur_freq, fit_quality_low, n_chans, my_chans_name);
end

function qual = make_fit_qual(subjid, cur_freq, fq, n_chans, my_chans_name)
subj_col = repmat(subjid, n_chans, 1);
freq_col = repmat(cur_freq, n_chans, 1);
chan_col = (1:n_chans)';
qual = table(subj_col, categorical(chan_col, 1:n_chans,my_chans_name), freq_col, ...
    fq.all.resnorm(:), fq.all.exitflag(:), fq.all.pinned(:,1), fq.all.pinned(:,2), fq.all.pinned(:,3), fq.all.pinned(:,4), ...
    fq.sim.resnorm(:), fq.sim.exitflag(:), fq.sim.pinned(:,1), fq.sim.pinned(:,2), fq.sim.pinned(:,3), fq.sim.pinned(:,4), ...
    'VariableNames',{'Subj_ID','Chan','Freq',...
    'Resnorm_All','Exitflag_All','Pin_a_All','Pin_k_All','Pin_x0_All','Pin_b_All' ...
    'Resnorm_Sim','Exitflag_Sim','Pin_a_Sim','Pin_k_Sim','Pin_x0_Sim','Pin_b_Sim' });

end
