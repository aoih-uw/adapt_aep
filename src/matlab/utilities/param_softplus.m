function [p, cur_data, cur_data_std, softplus, fit_ok, pinned] ...
    = param_softplus(cur_data, cur_data_std, amp_vec, noise_floor,weight_data)

%% Assing vars
% Force row
cur_data = cur_data(:).';  cur_data_std = cur_data_std(:).';  amp_vec = amp_vec(:).';

% Assign noise_floor
if isempty(noise_floor)
    softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + p(4);
else
    softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + noise_floor;
end

% Assign weight vectors
if weight_data & ~isempty(cur_data_std)
    weight_vec = 1./max(cur_data_std, max(0.01*mean(cur_data_std), eps));
else
    weight_vec = 1;
end

%% Assign upper/lower bounds and initial parameter values
% Init
rise_idx = find(cur_data > (cur_data(1) + 0.2*(max(cur_data)-cur_data(1))), 1, 'first');
if isempty(rise_idx), rise_idx = round(length(amp_vec)/2); end
x0_init = amp_vec(rise_idx);

base = cur_data(amp_vec < min(amp_vec) + 0.3*range(amp_vec));
a_init = (max(cur_data) - cur_data(rise_idx)) / max(max(amp_vec) - x0_init, 5);

p0 = [a_init, 0.3, x0_init];
lb = [0,   0.05, min(amp_vec)];
ub = [Inf, 1.0,  max(amp_vec)];
if isempty(noise_floor)
    p0 = [p0 median(base)];
    lb = [lb min(base) - range(base)];
    ub = [ub max(base)];
end
p0 = min(max(p0, lb), ub);

%% Fit model
[p, ~, r, exitflag, ~, ~, J] = lsqcurvefit(@(p,x) softplus(p,x).*weight_vec, p0, ...
    amp_vec, cur_data.*weight_vec, lb, ub, optimset('Display','off'));

%% Identify trials with pinned or non-converged fits
pinned = (isfinite(lb) & abs(p-lb) <= 1e-6*max(1,abs(lb))) | ...
         (isfinite(ub) & abs(p-ub) <= 1e-6*max(1,abs(ub)));
fit_ok = exitflag > 0 && ~any(pinned);