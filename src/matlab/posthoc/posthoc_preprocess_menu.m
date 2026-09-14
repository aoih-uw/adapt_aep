%% posthoc preprocess menu
clearvars
base_dir = 'D:\2026\Research\Aug Sept Midshipman\raw_data';
save_dir = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
figure_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data\figure_slides';
summary_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))
file_type = 'mixed_freqs';
% file_type = 'benzo';
old_vis = get(0,'DefaultFigureVisible');

%% Set this when doing bulk processing!
% set(0,'DefaultFigureVisible','off');
try
    subjids = 46;
    % subjids = [28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44];
    failed = [];
    for isubj = 1:length(subjids)
        clear meta org_data hydro_results sim_results T_ON_2f
        cur_subj = subjids(isubj);
        fprintf('\n=== Subject %d ===\n', cur_subj)
        try
            %% PREPROCESSING
            subjid = cur_subj;
            cd(base_dir)
            %% Load
            fprintf('\nLoading data...\n')
            grand_ex_save = posthoc_load_my_file(subjid,base_dir,file_type); % Load in data

            %% Sort
            fprintf('\nSorting data...\n')
            [meta, org_data] = posthoc_sort_data(grand_ex_save, base_dir, ...
                save_dir);

            %% Hydrophone signal
            fprintf('Plotting hydrophone signal');
            posthoc_hydrophone_analysis
            % Output hydro_results

            %% 2f Amplitude consistency across time
            posthoc_resp_consist

            %% Waterfall
            fprintf('\nPlotting waterfall...\n')
            posthoc_waterfall % Plot grand average waterfalls

            %% Simulate
            fprintf('\nSimulating adapt_aep...\n')
            posthoc_bootstrap_sim % Main analysis script

            %% Save preprocessed data
            cd(summary_loc)
            save(sprintf('subject_%d', cur_subj), ...
                'meta', 'hydro_results', 'sim_results', 'T_ON_2f', '-v7.3');

            % %% Apply Tufte styling
            apply_tufte

            %% Save figs
            save_figs_to_ppt(meta,figure_loc)
        catch ME
            fprintf(2, 'Subject %d failed: %s\n', cur_subj, ME.message);
            failed(end+1) = cur_subj;
        end
        close all
    end
    fprintf('\nFailed subjects: %s\n', mat2str(failed));
catch ME
    set(0,'DefaultFigureVisible',old_vis);
    rethrow(ME)
end
set(0,'DefaultFigureVisible',old_vis);

