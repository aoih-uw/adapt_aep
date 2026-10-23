% Categories are metadata they dont get removed when you filter the data
chan_inc = ["Subcranial","Subcutaneous"];
freq_inc = [55, 100, 410];
my_colors = {tableau_10('red'), tableau_10('blue'), tableau_10('orange'), tableau_10('teal'), tableau_10('purple'),tableau_10('yellow')};
my_color_order = [tableau_10('blue'); tableau_10('orange')];
set(groot, 'defaultAxesColorOrder', my_color_order);

% Significance variables
max_trials = 260;
trials_per_block = 10;
my_alpha = 0.01/(max_trials/trials_per_block);
log_trans_alpha = log10(finv(1 - my_alpha, 2, 2*(max_trials - 1)));

%% Growth Function
summary_plot_growth_function

%% Summary polar plot
summary_polar_plot

%% Plot consistency of 2f response
summary_plot_2f_consistency

%% F Fit Quality summary
summary_plot_F_fit_quality

%% F GF Model Fit Parameters Box plot
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
save_figs_to_ppt(outdir, 'Midshipman AEP Summary Stats 2026')
