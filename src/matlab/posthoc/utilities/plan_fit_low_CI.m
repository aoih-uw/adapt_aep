function [all_data, ds_data, bottom_up, top_down] = ...
    plan_fit_low_CI(amp_vec, lower_ci_vec, boot_std_vec, trials_per_block, max_trials, my_chans_name)

% All_data available data
[p, thresh_ci, stable_n] = ...
    fit_low_CI_model(amp_vec, lower_ci_vec, boot_std_vec, ...
    trials_per_block, max_trials, my_chans_name, 'all_data data',1);

% Save values
all_data.amp_vec = amp_vec;
all_data.p = p;
all_data.thresh_ci = thresh_ci;
all_data.stable_n = stable_n;

% Decreasing amplitude resolution
orig_res = diff(amp_vec(1:2));
ds_factors = [2 3 5 6];

for istep = 1:length(ds_factors)
    % Downsample amplitude vector
    cur_idx = 1:ds_factors(istep):length(amp_vec);
    cur_idx(end) = length(amp_vec);
    amp_vec_ds = amp_vec(cur_idx);

    % Generate bias ID tag
    my_tag = sprintf('Downsample by %d',ds_factors(istep));

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        trials_per_block, max_trials, my_chans_name, my_tag,1);

    % Save values
    ds_data(istep).amp_vec_ds = amp_vec_ds;
    ds_data(istep).ds_factor = diff(amp_vec_ds(1:2));
    ds_data(istep).p = p;
    ds_data(istep).thresh_ci = thresh_ci;
    ds_data(istep).stable_n = stable_n;

end

% Delete from bottom up
for iamp = 2:(length(amp_vec)-2) % Start at 2 since we already know what it looks like with all_data data points included
    % Remove data points
    amp_vec_ds = amp_vec(iamp:end);
    cur_idx = find(ismember(amp_vec,amp_vec_ds));
    n_points_deleted = length(amp_vec)-length(amp_vec_ds);

    % Generate bias ID tag
    my_tag = sprintf('Bottom-up %d points deleted',n_points_deleted);

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        trials_per_block, max_trials,my_chans_name, my_tag,0);

    % Save values
    bottom_up(iamp-1).amp_vec_ds = amp_vec_ds;
    bottom_up(iamp-1).ds_factor = n_points_deleted;
    bottom_up(iamp-1).p = p;
    bottom_up(iamp-1).thresh_ci = thresh_ci;
    bottom_up(iamp-1).stable_n = stable_n;

end

% Delete from top down
for iamp = 1:(length(amp_vec)-3)

    % Delete data points
    amp_vec_ds = amp_vec(1:end-iamp);
    cur_idx = find(ismember(amp_vec,amp_vec_ds));
    n_points_deleted = length(amp_vec)-length(amp_vec_ds);

    % Generate bias ID tag
    my_tag = sprintf('Top-down %d points deleted',n_points_deleted);

    [p, thresh_ci, stable_n] = ...
        fit_low_CI_model(amp_vec_ds, lower_ci_vec(:,cur_idx,:), boot_std_vec(:,cur_idx,:), ...
        trials_per_block, max_trials,my_chans_name, my_tag,0);

    % Save values
    top_down(iamp).amp_vec_ds = amp_vec_ds;
    top_down(iamp).ds_factor = n_points_deleted;
    top_down(iamp).p = p;
    top_down(iamp).thresh_ci = thresh_ci;
    top_down(iamp).stable_n = stable_n;

end