%% Posthoc calc_summary_stats
% Create a cross subject summary table
% Load in presummary tables by subject and combine into one mega table
% Remember to remove subject 37
subjids = [29 30 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46 47 48 49 50 51];
sort_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
presum_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
outdir =  'D:\2026\Research\Aug Sept Midshipman\pre_summary';
cd(presum_loc)
all_sim = struct('resp_found',{},'F_fit',{},'threshold',{});
hydro_results = struct('hydro',{});

% Loop through subjects
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
    F = [S.sim_results.F];
    twof = [S.sim_results.twof];

    % Hydrophone
    hydro_results(isubj).hydro = vertcat(S.hydro_results);
    
    % How many trials needed to detect response
    all_sim(isubj).F_resp_found = vertcat(S.sim_results.F_resp_found);

    % F Model
    all_sim(isubj).model_p = vertcat(F.p); % F model fit parameters
    all_sim(isubj).F_vals = vertcat(F.summary); % raw F values for each subject 
    all_sim(isubj).F_fitq = vertcat(F.fit_q); % Fit quality of F model fit
    all_sim(isubj).threshold = vertcat(F.thresholds); % Thresholds from F model fit, including bootstrapped mean, lowCI and UpCI values
  
    % Typical 2f growth function
    all_sim(isubj).twof = vertcat(twof.summary);

    % Response consistency slope
    all_sim(isubj).slope = vertcat(S.T_slope);
    all_sim(isubj).twof_over_time = vertcat(S.T_ON_2f);

    % Polar plots
    all_sim(isubj).polar = vertcat(S.sim_results.polar);

    % Data removal error plots
    all_sim(isubj).error = vertcat(S.T_error);

end

% Sort Tables
T_Frf = vertcat(all_sim.F_resp_found); % F response found heatmaps
T_F = vertcat(all_sim.F_vals); % Raw F values to plot with
T_F_fitq = vertcat(all_sim.F_fitq); % Fit quality
T_twof = vertcat(all_sim.twof); % 2f growth function
T_thresh = vertcat(all_sim.threshold); 
T_mp = vertcat(all_sim.model_p); % F model fit parameters (e.g., a,k,x0,b)
T_hydro = vertcat(hydro_results.hydro); % Hydrophone data
T_slope = vertcat(all_sim.slope); % Slope of 2f response across experiment time
T_twof_over_time = vertcat(all_sim.twof_over_time); % Raw 2f response over experiment time
T_wl = readtable('weight_length_table.xlsx'); % Weight vs. Length data
T_polar = vertcat(all_sim.polar); % Polar plots all data, all trials, no adaptive
T_error = vertcat(all_sim.error); % Error associated with incremental data deletion (robustness measure)

%% Merge "subcutaneous"/"Subcutaneous" in all tables
T_Frf = fixChan(T_Frf);
T_F = fixChan(T_F);
T_F_fitq = fixChan(T_F_fitq);
T_twof = fixChan(T_twof);
T_thresh = fixChan(T_thresh);
T_mp = fixChan(T_mp);
T_hydro = fixChan(T_hydro);
T_slope = fixChan(T_slope);
T_twof_over_time = fixChan(T_twof_over_time);
T_polar = fixChan(T_polar);
T_wl = fixChan(T_wl);
T_error = fixChan(T_error);

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
