%% convert_sim_data_to_long
function sim_results = convert_sim_data_to_long(subjid, cur_freq, amp_vec, it_vec, CI_vec, ...
    boot_count, F_count, twof_growth, low_growth, fit_quality_low, ...
    my_chans, my_chans_name, cumu, polar)

% Assign variables
sim_results = struct();
n_chans = numel(my_chans);

%% Polar plot summary stats
[Amp, Chan] = ndgrid(amp_vec,1:n_chans); % Variable order needs to match polar
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
polar_table = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name),freq_col, Amp(:), ...
   polar.ON.n(:), polar.ON.mag.mean(:), polar.OFF.mag.mean(:),...
   polar.ON.angle.mean(:), polar.OFF.angle.mean(:), ...
   polar.ON.mag.std(:), polar.OFF.mag.std(:), ...
   polar.ON.PLV(:), polar.OFF.PLV(:), ...
   'VariableNames',{'Subj_ID','Chan','Freq', 'Amp', 'N_trials' ...
   'Mag_ON', 'Mag_OFF', 'Angle_ON','Angle_OFF', 'Std_ON', 'Std_OFF', 'PLV_ON', 'PLV_OFF'});

%% Cumulative F Stats table
n_batches = size(cumu.n,1);
[Batches,Amp, Chan] = ndgrid(1:n_batches,amp_vec,1:n_chans); % Variable order needs to match polar
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
col = @(X,k) reshape(X(:,k,:,:), [], 1); % Pull stat k out as one column
F_stats_table = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name),freq_col, Amp(:), ...
   Batches(:),cumu.n(:), col(cumu.F_stats_ON,1), col(cumu.F_stats_ON,2), ...
    col(cumu.F_stats_ON,3), col(cumu.F_stats_ON,4), ...
   'VariableNames',{'Subj_ID','Chan','Freq', 'Amp', 'Batch','N_trials' ...
   'PLV', 'R','F','p'});

% Store varialbes
sim_results.polar = polar_table;
sim_results.F_stats = F_stats_table;

%% Resp_found heatmap
% Boot
[Chan, Amp, IT, CI] = ndgrid(1:n_chans,amp_vec, it_vec,CI_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
boot_resp_found = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name),freq_col, Amp(:), ...
    IT(:), CI(:), boot_count.stable(:), boot_count.first(:), boot_count.inconsist(:), ...
    'VariableNames',{'Subj_ID','Chan','Freq', 'Amp',...
    'Boot_It_N','CI','Stable','First','N_Inconsist'});

% F stat
[Chan, Amp] = ndgrid(1:n_chans,amp_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
F_resp_found = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name),freq_col, Amp(:), ...
    F_count.stable(:), F_count.first(:), F_count.inconsist(:), ...
    'VariableNames',{'Subj_ID','Chan','Freq', 'Amp',...
    'Stable','First','N_Inconsist'});

% Store
sim_results.boot_resp_found = boot_resp_found;
sim_results.F_resp_found = F_resp_found;

%% 2f growth functions
% Summary vals
[Chan, Amp] = ndgrid(1:n_chans, amp_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
twof_summary = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name), freq_col, Amp(:), ...
    twof_growth.mean(:), twof_growth.sem(:), twof_growth.noise_floor(:), ...
    'VariableNames',  {'Subj_ID','Chan','Freq','Amp','Mean','SEM','Noise_Floor'});

% Store variables
sim_results.twof.summary = twof_summary;

%% Low CI growth functions
%% now low_growth.all vs. low_growth.sim
% Summary vals
[Chan, Amp] = ndgrid(1:n_chans, amp_vec);
subjid_col = repmat(subjid,length(Chan(:)),1);
freq_col = repmat(cur_freq,length(Chan(:)),1);
lowCI_summary = table(subjid_col, categorical(Chan(:),1:n_chans,my_chans_name), freq_col, Amp(:), ...
    low_growth.all.low_CI(:), low_growth.sim.low_CI(:), ...
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
