function [bootstat, lower_CI, upper_CI] = calculate_bootstrap(n_bootstrap, ON,OFF, my_CI)
% my_CI may be a scalar or a vector of CI levels; lower_CI/upper_CI match its shape
if iscell(ON),  ON  = ON{1};  end
if iscell(OFF), OFF = OFF{1}; end
ON = ON(:); OFF = OFF(:);

% Generate matrix that creates n_bootstrap resampling of number of trials
% availble in ON/OFF, each column = one resample, there will be n_bootstrap
% columns. Randi allows resampling with replacement. 
idx = randi(numel(ON),numel(ON),n_bootstrap);

%% Assign CI upper and lower bounds (Two sided CI)
outer = (100 - my_CI(:).')/2;   % row vector
ub = 100-outer;
lb = outer;

%% Bootstrap!
% Average using complex numbers and then take the abs() to recover magnitude
% Can get negative values, but lose trial-level artefact subtraction, but
% that may be ok
bootstat = (abs(mean(ON(idx),1)) - abs(mean(OFF(idx),1))).';

%% Calculate 99.9% CI
lower_CI = prctile(bootstat, lb);
upper_CI = prctile(bootstat, ub);

end