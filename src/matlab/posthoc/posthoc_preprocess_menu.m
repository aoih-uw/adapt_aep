%% posthoc preprocess menu
clearvars
base_dir = 'D:\2026\Research\Aug Sept Midshipman\raw_data';
sort_dir = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
figure_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data\figure_slides';
summary_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))
old_vis = get(0,'DefaultFigureVisible');

% Decide wether to load in raw file
load_raw_file = 0;
file_type = 'mixed_freqs';
% file_type = 'benzo';

%% Set this when doing bulk processing!
set(0,'DefaultFigureVisible','off');
try
    % subjids = 52;
    subjids = [29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51];
    failed = [];
    failed_files_all = {};
    for isubj = 1:length(subjids)
        clear meta org_data hydro_results sim_results T_ON_2f
        cur_subj = subjids(isubj);
        fprintf('\n=== Subject %d ===\n', cur_subj)
        try
            if load_raw_file % Load in raw file
            [my_names] = find_files(cur_subj,base_dir,[],[],file_type,1);
            grand_ex_save = {};
            failed_files = {};
            for iname = 1:numel(my_names)
                current_file = my_names{iname};
                fprintf('Loading %s, %d/%d\n', current_file, iname, numel(my_names))
                try
                    S = load(current_file);
                    grand_ex_save{end+1} = S.ex_save;
                catch ME
                    fprintf('  Skipping %s: %s\n', current_file, ME.message);
                    failed_files{end+1} = fullfile(pwd, current_file);
                end
            end

            %% Sort
            fprintf('\nSorting data...\n')
            [meta, org_data] = posthoc_sort_data(grand_ex_save, base_dir, ...
                sort_dir);

            else % Load in pre-sorted data
                [my_names] = find_files(cur_subj,sort_dir,[],[],'Mixed freqs',0);
                my_names = sort(my_names);
                load(my_names{end})
            end

            %% Hydrophone signal
            fprintf('Plotting hydrophone signal...\n');
            posthoc_hydrophone_analysis
            % Output hydro_results

            % 2f Amplitude consistency across time
            posthoc_resp_consist

            % %% Waterfall
            % fprintf('\nPlotting waterfall...\n')
            % posthoc_waterfall % Plot grand average waterfalls

            %% Simulate
            fprintf('\nSimulating adapt_aep...\n')
            posthoc_bootstrap_sim % Main analysis script

            %% Save preprocessed data
            fprintf('\nSaving summary data...\n')
            cd(summary_loc)
            save(sprintf('subject_%d', cur_subj), ...
                'meta', 'hydro_results', 'sim_results', 'T_ON_2f', 'T_slope','-v7.3');

            % % %% Apply Tufte styling
            % apply_tufte

            % %% Save figs
            % fprintf('\nSaving to ppt...\n')
            % save_figs_to_ppt(meta,figure_loc)
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

