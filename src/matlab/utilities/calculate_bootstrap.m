function [bootstat, lower_CI, upper_CI] = calculate_bootstrap(n_bootstrap, selected_vector)
if iscell(selected_vector)
    selected_vector = selected_vector{:};
end

% Bootstrap!
bootstat = bootstrp(n_bootstrap,@mean,selected_vector);

%% Calculate 99% CI
lower_CI = prctile(bootstat, 0.5);
upper_CI = prctile(bootstat, 99.5);

end