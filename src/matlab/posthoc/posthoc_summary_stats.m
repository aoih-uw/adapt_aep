%% Posthoc calc_summary_stats
% Create a cross subject summary table
% Load in presummary tables by subject and combine into one mega table
subjids = [29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51];
sort_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
presum_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
cd(presum_loc)
all_sim = struct('resp_found',{},'lowCI_fit',{},'threshold',{});
all_hydro = struct('ON',{},'noise',{});
max_trials = 260;

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

    % Hydrophone
    all_hydro(isubj).ON = vertcat(S.hydro_results.ON);
    all_hydro(isubj).noise = vertcat(S.hydro_results.noise);
    
    % How many trials needed to detect response
    all_sim(isubj).resp_found = vertcat(S.sim_results.resp_found);

    % Low CI Model 
    all_sim(isubj).model_p = vertcat(lowCI.p); % Vertcat across all frequencies
    all_sim(isubj).lowCI_vals = vertcat(lowCI.summary); % raw lowCI values for each subject 
    all_sim(isubj).lowCI_fitq = vertcat(lowCI.fit_q);
    all_sim(isubj).threshold = vertcat(lowCI.thresholds);
  
    % Typical 2f growth function
    all_sim(isubj).twof = vertcat(twof.summary);

    % Response consistency slope
    all_sim(isubj).slope = vertcat(S.T_slope);

end

% Sort Tables
T_rf = vertcat(all_sim.resp_found);
T_lowCI = vertcat(all_sim.lowCI_vals);
T_lowCI_fitq = vertcat(all_sim.lowCI_fitq);
T_twof = vertcat(all_sim.twof);
T_thresh = vertcat(all_sim.threshold);
T_mp = vertcat(all_sim.model_p);
T_hydro_noise = vertcat(all_hydro.noise);
T_hydro_ON = vertcat(all_hydro.ON);
T_slope = vertcat(all_sim.slope);
T_wl = readtable('weight_length_table.xlsx');

% Merge "subcutaneous"/"Subcutaneous" in all tables
T_rf = fixChan(T_rf);
T_lowCI = fixChan(T_lowCI);
T_lowCI_fitq = fixChan(T_lowCI_fitq);
T_twof = fixChan(T_twof);
T_thresh = fixChan(T_thresh);
T_mp = fixChan(T_mp);
T_hydro_noise = fixChan(T_hydro_noise);
T_hydro_ON = fixChan(T_hydro_ON);
T_slope = fixChan(T_slope);
T_wl = fixChan(T_wl);

%% Plot!
summary_stats_plotter

%% Local functions
function T = fixChan(T)
    if ismember('Chan', T.Properties.VariableNames)
        T.Chan = categorical(T.Chan);
        old = intersect(["subcutaneous","Subcutaneous"], categories(T.Chan));
        if ~isempty(old)
            T.Chan = mergecats(T.Chan, old, "Subcutaneous");
        end
    end
end
