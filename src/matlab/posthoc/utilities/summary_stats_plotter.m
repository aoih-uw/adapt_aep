% Categories are metadata they dont get removed when you filter the data
outdir = 'F:\2026\Research\Aug Sept Midshipman\pre_summary';
chan_inc = ["Subcutaneous", "Subcranial"];
freq_inc = [55, 100, 410];

%% Plot consistency of 2f response
summary_plot_2f_consistency

%% Low CI Fit Quality summary
summary_plot_low_CI_fit_quality

%% Growth Function
summary_plot_growth_function

%% Lower CI GF Model Fit Parameters Box plot
summary_plot_GF_fit_params

%% Hydrophone Acoustics Summary
summary_plot_hydro_acoustics

%% HEATMAP
summary_heatmap

%% Create summary threshold table
summary_create_threshold_table

%% Compare Thresholds
summary_threshold_comparisons

%% Threshold Box plot
summary_threshold_boxplot

% Apply Tufte
apply_tufte

% % Save figs to powerpoint
% save_figs_to_ppt(outdir, 'Midshipman AEP Summary Stats 2026')
