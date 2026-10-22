%% posthoc_analyze_accelerometer
clearvars
base_dir = 'D:\2026\Research\Aug Sept Midshipman\raw_data';
sort_dir = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
figure_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data\figure_slides';
summary_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))
old_vis = get(0,'DefaultFigureVisible');

% Decide wether to load in raw file
load_raw_file = 1;
file_type = 'accelerometer';
set(0,'DefaultFigureVisible','on');

try
    subjids = 54;
    failed = [];
    failed_files_all = {};
    for isubj = 1:length(subjids)
        clear meta org_data
        cur_subj = subjids(isubj);
        fprintf('\n=== Subject %d ===\n', cur_subj)
        try

            %% Load data
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
                        failed_files{end+1} = fullfile(current_file);
                    end
                end

                failed_files_all = [failed_files_all, failed_files];
            end

            %% Sort accelerometer data (and calculate dB...)
            sort_accelerometer_data

            %% Process accelerometer ffts
            process_accelerometer_ffts

            %% Apply Tufte styling
            apply_tufte

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
