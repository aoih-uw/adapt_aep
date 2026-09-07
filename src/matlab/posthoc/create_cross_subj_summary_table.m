%% create_cross_subj_summary_table
%% Load in presummary tables by subject and combine into one mega table
subjids = [28 33 34 35 36 37 38];
sort_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
presum_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
cd(presum_loc)
all_sim = struct('resp_found',{},'lowCI_fit',{},'threshold',{});

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
    S = load(fullfile(presum_loc, files(1).name), 'sim_results');
    lowCI = [S.sim_results.lowCI];
    all_sim(isubj).resp_found = vertcat(S.sim_results.resp_found); % Vertcat across all frequencies
    all_sim(isubj).lowCI_fit = vertcat(lowCI.fit);
    all_sim(isubj).threshold = vertcat(lowCI.thresholds);

end

rf_T = vertcat(all_sim.resp_found);
fit_T = vertcat(all_sim.lowCI_fit);
thresh_T = vertcat(all_sim.threshold);
