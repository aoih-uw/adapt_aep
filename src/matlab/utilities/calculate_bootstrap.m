function [bootstat, lower_CI, upper_CI] = calculate_bootstrap(n_bootstrap, selected_vector, my_CI)
if iscell(selected_vector)
    selected_vector = selected_vector{:};
end

% Assign CI upper and lower bounds
outer = (100-my_CI)/2;
ub = 100-outer;
lb = outer;

% Bootstrap!
bootstat = bootstrp(n_bootstrap, @(x) abs(mean(x)), selected_vector); 
% Average using complex numbers and then take the abs() to recover magnitude

%% Calculate 99.9% CI
lower_CI = prctile(bootstat, lb);
upper_CI = prctile(bootstat, ub);

end