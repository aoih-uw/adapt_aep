function [cur_boot_mean, cur_boot_std, resp_found,lower_CI] = ...
    simulate_bootstrap(n_bootstrap,my_data,my_CI)

% Run bootstrap on current batch of data
[bootstat, lower_CI, ~] = ...
    calculate_bootstrap(n_bootstrap, my_data,my_CI);

% Calculate distribution metrics
cur_boot_mean = mean(bootstat);
cur_boot_std = std(bootstat);
resp_found = lower_CI > 0;