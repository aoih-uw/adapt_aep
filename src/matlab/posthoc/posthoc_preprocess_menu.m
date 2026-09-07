%% posthoc preprocess menu

%% PREPROCESSING
clearvars
addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))
subjid = 38;
base_dir = 'D:\2026\Research\Aug Sept Midshipman\raw_data';
save_dir = 'D:\2026\Research\Aug Sept Midshipman\sorted_data';
figure_loc = 'D:\2026\Research\Aug Sept Midshipman\sorted_data\figure_slides';
summary_loc = 'D:\2026\Research\Aug Sept Midshipman\pre_summary';
file_type = 'mixed_freqs';
% file_type = 'benzo';

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
save(sprintf('subject_%d', subjid), ...
    'meta', 'hydro_results', 'sim_results', '-v7.3');

% %% Apply Tufte styling
% apply_tufte
% 
% %% Save figs
% save_figs_to_ppt(meta,figure_loc)

