function [p, cur_data, trials_needed, softplus, fit_ok, pinned] ...
    = param_softplus(cur_data, trials_needed, amp_vec, noise_floor,weight_data)

%% Assing vars
% Force row
cur_data = cur_data(:).';  trials_needed = trials_needed(:).';  amp_vec = amp_vec(:).';

% Define function
softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + p(4);

% Assign weight vectors
if weight_data & ~isempty(trials_needed)
    weight_vec = sqrt(1./trials_needed);
else
    weight_vec = 1;
end

%% Assign upper/lower bounds and initial parameter values
% Init
rise_idx = find(cur_data > (cur_data(1) + 0.2*(max(cur_data)-cur_data(1))), 1, 'first');
if isempty(rise_idx), rise_idx = round(length(amp_vec)/2); end
x0_init = amp_vec(rise_idx);

if isempty(noise_floor)
    % Take the first 30% of data
    base = cur_data(amp_vec < min(amp_vec) + 0.3*range(amp_vec));
else
    base = noise_floor;
end
p0 = min(max(p0, lb), ub);

% after `base` is computed, before the fit
s = max(std(cur_data(amp_vec < min(amp_vec) + 0.3*range(amp_vec))), eps);
tf = @(y) asinh(y./s); % Squashes larger y values, keeps small y values the same

% Have lb/ub wide open
a_init = (max(cur_data) - cur_data(rise_idx)) / max(max(amp_vec) - x0_init, 5);
p0 = [a_init, 0.3, x0_init median(base)];
lb = [0,   0, min(amp_vec) -inf];
ub = [Inf, Inf,  max(amp_vec) inf];

p0 = min(max(p0, lb), ub);

%% Fit model
[p, ~, r, exitflag, ~, ~, J] = lsqcurvefit(@(p,x) tf(softplus(p,x)).*weight_vec, p0, ...
    amp_vec, tf(cur_data).*weight_vec, lb, ub, optimset('Display','off'));

%% Identify trials with pinned or non-converged fits
pinned = (isfinite(lb) & abs(p-lb) <= 1e-6*max(1,abs(lb))) | ...
         (isfinite(ub) & abs(p-ub) <= 1e-6*max(1,abs(ub)));
fit_ok = exitflag > 0 && ~any(pinned);