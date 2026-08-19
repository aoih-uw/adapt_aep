function [bootstat, lower_CI, upper_CI] = calculate_bootstrap(n_bootstrap, ON,OFF, my_CI)
if iscell(ON),  ON  = ON{1};  end
if iscell(OFF), OFF = OFF{1}; end
ON = ON(:); OFF = OFF(:);

% Assign CI upper and lower bounds
outer = (100-my_CI)/2;
ub = 100-outer;
lb = outer;

% Bootstrap!
bootstat = bootstrp(n_bootstrap, @(on,off) abs(mean(on)) - abs(mean(off)), ON, OFF);
% Average using complex numbers and then take the abs() to recover magnitude

%% Calculate 99.9% CI
lower_CI = prctile(bootstat, lb);
upper_CI = prctile(bootstat, ub);

end