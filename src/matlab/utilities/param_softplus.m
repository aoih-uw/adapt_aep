function [p, cur_data, my_weights, softplus, fit_quality] ...
    = param_softplus(cur_data, my_weights, amp_vec, noise_floor, weight_data)
%% 10/14/2026: param_softplus will not use asinh anymore to transform the
% data. This means for model fits for threshold finding, the data must be
% transformed (using -log10(x) for example) before using in this function.
% Normal growth functions used for illustrative purposes won't use (or
% likely need) this correction factor, since it was initially used
% specifically to better fit lower asymptote small values

%% Assign vars
% Force row
cur_data = cur_data(:).';  my_weights = my_weights(:).';  amp_vec = amp_vec(:).';

% Define function
softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + p(4);

%% Assign weight vectors
% 10/2/2026 Ensure shouldn't be applying any weights... across adapt_aep
if weight_data & ~isempty(my_weights)
    fprintf('param_softplus: Weights applied when we shouldnt be!\n')
    weight_vec = 1;
else
    weight_vec = 1;
end

%% Identify the noise floor / y value of the lower asymptote
if isempty(noise_floor)
% Take the first 30% of data
    base = cur_data(amp_vec < min(amp_vec) + 0.3*range(amp_vec));
else
    base = noise_floor;
end

%% Assign upper/lower bounds and initial parameter values
% x0 init
% Find at which point the ydata value is greater than 20% of the max,
% define this as the rising point
rise_idx = find(cur_data > (cur_data(1) + 0.2*(max(cur_data)-cur_data(1))), 1, 'first');
% If no rise_idx found, because the function is noisy, just choose the middle idx value
if isempty(rise_idx), rise_idx = round(length(amp_vec)/2); end
x0_init = amp_vec(rise_idx);

% a init
% The slope from when the function rises to the max point of the function
% Rise = y change; run = x change across the y change
a_init = (max(cur_data) - cur_data(rise_idx)) / max(max(amp_vec) - x0_init, 5);

% Set initial guesses
% a, k, x0, b
% k = 0.3 is a middle-ground starting point
p0 = [a_init, 0.3, x0_init median(base)];

% Set lb/ub wide open
lb = [0,   1e-3, min(amp_vec) -inf];
ub = [Inf, Inf,  max(amp_vec) inf];

% Clamp each starting guess within its allowed range
p0 = min(max(p0, lb), ub);

%% Fit model
[p, resnorm, ~, exitflag, ~, ~, ~] = lsqcurvefit(@(p,x) softplus(p,x).*weight_vec, p0, ...
    amp_vec, cur_data.*weight_vec, lb, ub, optimset('Display','off'));

%% Identify trials with pinned or non-converged fits
% Did the fitter end up pressed against one of the limits I set? If so the
% selected parameter is suspect since the fitter was not able to reach the
% value it likely was intending to achieve
% abs(p-lb) <= 1e-6*max(1,abs(lb))
%       abs(p-lb) is the distance between fit and bound
%       1e-6 is the allowed tolerance (one millionth of the bound's size)
%       max(1,abs(lb)) ensures if lb == 0, that you don't multiply 1e-6 by 0
pinned = (isfinite(lb) & abs(p-lb) <= 1e-6*max(1,abs(lb))) | ...
         (isfinite(ub) & abs(p-ub) <= 1e-6*max(1,abs(ub)));

fit_quality.resnorm  = resnorm;
fit_quality.exitflag = exitflag;
fit_quality.pinned   = pinned(:).';
