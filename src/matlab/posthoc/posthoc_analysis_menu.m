%% posthoc analysis menu
clearvars
addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))
subjid = 37;
base_dir = 'F:\2026\Research\Aug Sept Midshipman\raw_data';
save_dir = 'F:\2026\Research\Aug Sept Midshipman\sorted_data';
figure_loc = 'F:\2026\Research\Aug Sept Midshipman\sorted_data\figure_slides';
file_type = 'mixed_freqs';

%% Load
fprintf('\nLoading data...\n')
grand_ex_save = posthoc_load_my_file(subjid,base_dir,file_type); % Load in data

%% Organize
fprintf('\nOrganizing data...\n')
[meta, org_data] = posthoc_organize_data(grand_ex_save, base_dir, ...
    save_dir); % preprocess data

%% Hydrophone signal
fprintf('Plotting hydrophone signal');
posthoc_hydrophone_analysis

%% Waterfall
fprintf('\nPlotting waterfall...\n')
posthoc_waterfall % Plot grand average waterfalls

%% Simulate
fprintf('\nSimulating adapt_aep...\n')
posthoc_bootstrap_sim % Main analysis script

%% Apply Tufte styling
apply_tufte

%% Save figs
save_figs_to_ppt(meta,figure_loc)