%% create_cross_subj_summary_table
subjids = [28 33 34 35 36 37];
sort_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
presum_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';

%% Make datasets
for isubj = 1:length(subjids)
    cd(sort_loc)
    cur_subj = subjids(isubj);
    myname = sprintf('subject_%d_*',cur_subj);
    files = dir(myname);
    if isempty(files)
        fprintf('No files found')
    else
        my_names = {files.name};
    end

    for iname = 1:numel(my_names)
        current_file = my_names{iname};
        fprintf('Loading %s, %d/%d\n', current_file, iname, numel(my_names))
        try
            load(current_file);
        end
    end

    posthoc_hydrophone_analysis % hydro_results
    posthoc_bootstrap_sim % sim_results

    cd(presum_loc)
    save(sprintf('subject_%d',cur_subj),'hydro_results','sim_results')
end

%% Load in presummary tables
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
