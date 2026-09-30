%% posthoc preprocess menu
clearvars
base_dir = 'C:\Users\Aoi Hunsaker\Desktop\adapt_aep\data\aep';
save_dir = 'C:\Users\Aoi Hunsaker\Downloads';
figure_loc = 'C:\Users\Aoi Hunsaker\Downloads';
summary_loc = 'C:\Users\Aoi Hunsaker\Downloads';
addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))
old_vis = get(0,'DefaultFigureVisible');

% Decide wether to load in raw file
load_raw_file = 0;
file_type = 'mixed_freqs';
% file_type = 'benzo';

%% Set this when doing bulk processing!
% set(0,'DefaultFigureVisible','off');
try
    subjids = 53;
    % subjids = [28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50];
    failed = [];
    failed_files_all = {};
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
            [grand_ex_save, bad_files] = posthoc_load_my_file(subjid,base_dir,file_type);
            failed_files_all = [failed_files_all, bad_files];

            %% Sort
            fprintf('\nSorting data...\n')
            [meta, org_data] = posthoc_sort_data(grand_ex_save, base_dir, ...
                sort_dir);

            else % Load in pre-sorted data
                [my_names] = find_files(cur_subj,sort_dir,[],[],'Mixed freqs',0);
                if numel(my_names) == 1
                    load(my_names{1})
                else
                    load(my_names{end})
                end
            end

            % %% Hydrophone signal
            % fprintf('Plotting hydrophone signal');
            % posthoc_hydrophone_analysis
            % % Output hydro_results

            %% 2f Amplitude consistency across time
            posthoc_resp_consist
            % 
            % %% Waterfall
            % fprintf('\nPlotting waterfall...\n')
            % posthoc_waterfall % Plot grand average waterfalls
            % 
            % %% Simulate
            % fprintf('\nSimulating adapt_aep...\n')
            % posthoc_bootstrap_sim % Main analysis script

            %% Save preprocessed data
            fprintf('\nSaving summary data...\n')
            cd(summary_loc)
            % save(sprintf('subject_%d', cur_subj), ...
            %     'meta', 'hydro_results', 'sim_results', 'T_ON_2f', 'T_slope','-v7.3');

            save(sprintf('subject_%d', cur_subj), ...
                'meta', 'hydro_results', 'sim_results', 'T_ON_2f', 'T_slope','-v7.3');

            % % %% Apply Tufte styling
            % apply_tufte

            %% Save figs
            fprintf('\nSaving to ppt...\n')
            save_figs_to_ppt(meta,figure_loc)
        catch ME
            fprintf(2, 'Subject %d failed: %s\n', cur_subj, ME.message);
            failed(end+1) = cur_subj;
        end
        close all
    end
    fprintf('\nFailed subjects: %s\n', mat2str(failed));
    fprintf('\nFiles that failed to load:\n');
    fprintf('  %s\n', failed_files_all{:});
catch ME
    set(0,'DefaultFigureVisible',old_vis);
    rethrow(ME)
end
set(0,'DefaultFigureVisible',old_vis);

