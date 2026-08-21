%% posthoc analysis menu
% Setup
if ~strcmp(questdlg('Clear all variables?','Confirm','Yes','No','No'),'Yes')
    return
end
clearvars
addpath(genpath('C:\Users\Aoi Hunsaker\Desktop\adapt_aep\src\matlab\'))
subjid = 29;
base_dir = 'D:\2026\Research\August Midshipman';
save_dir = 'D:\2026\Research\August Midshipman\organized_data';
file_type = 'mixed_freqs';
figure_loc = 'C:\Users\AEP\Downloads';

%% Load
fprintf('\nLoading data...\n')
grand_ex_save = posthoc_load_my_file(subjid,base_dir,file_type); % Load in data

%% Organize
fprintf('\nOrganizing data...\n')
[meta, org_data] = posthoc_organize_data(grand_ex_save, base_dir, ...
    save_dir); % preprocess data

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