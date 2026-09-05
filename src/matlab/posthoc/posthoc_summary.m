%% posthoc_summary
summary_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
cd(summary_loc)

subjids = 29:35;
all_results = struct([]);

for isubj = 1:length(subjids)
    cur_subj = subjids(isubj);
    files = dir(sprintf('subject_%d_presum*',cur_subj));

    % Check for empty files
    if isempty(files)
        fprintf('No files found')
        continue
    end

    % Find newest file
    [~, newest] = max([files.datenum]);
    fprintf('Loading %s\n', files(newest).name);
    S = load(files(newest.name));

    all_results(isubj).subjid = cur_subj;
    all_results(isubj).meta = S.meta;
    all_results(isubj).hydro = S.hydro_results;
    all_results(isubj).sim = S.sim_results;

end

% Compile hydrophone results
for isubj = 1:length(subjids)

    all_results(isubj).hydro.my_stim_ON

 

end