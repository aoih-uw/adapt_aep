%% Posthoc calc_summary_stats

% Create a cross subject summary table
%% Load in presummary tables by subject and combine into one mega table
subjids = [28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50];
sort_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
presum_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
cd(presum_loc)
all_sim = struct('resp_found',{},'lowCI_fit',{},'threshold',{});
all_hydro = struct('ON',{},'noise',{});

for isubj = 1:length(subjids)
    cur_subj = subjids(isubj);
    myname = sprintf('subject_%d*',cur_subj);
    files = dir(myname);
    if isempty(files)
        fprintf('No files found for subject %d\n', cur_subj)
        continue
    end

    fprintf('Loading %s\n', files(1).name)

    % Load and sort
    S = load(fullfile(presum_loc, files(1).name));
    lowCI = [S.sim_results.lowCI];
    twof = [S.sim_results.twof];
    all_hydro(isubj).ON = vertcat(S.hydro_results.ON);
    all_hydro(isubj).noise = vertcat(S.hydro_results.noise);
    all_sim(isubj).resp_found = vertcat(S.sim_results.resp_found);
    all_sim(isubj).model_p = vertcat(lowCI.p); % Vertcat across all frequencies
    all_sim(isubj).lowCI = vertcat(lowCI.summary);
    all_sim(isubj).lowCI_fp = vertcat(lowCI.fit_q);
    all_sim(isubj).twof = vertcat(twof.summary);
    all_sim(isubj).threshold = vertcat(lowCI.thresholds);

end

% Sort Tables
rf_T = vertcat(all_sim.resp_found);
lowCI_T = vertcat(all_sim.lowCI);
lowCI_fp_T = vertcat(all_sim.lowCI_fp);
twof_T = vertcat(all_sim.twof);
thresh_T = vertcat(all_sim.threshold);
mp_T = vertcat(all_sim.model_p);
hydro_noise = vertcat(all_hydro.noise);
hydro_ON = vertcat(all_hydro.ON);
wl_T = readtable('weight_length_table.xlsx');

save('all_subj','rf_T',"lowCI_T","thresh_T","mp_T")

%% Plot!
summary_stats_plotter