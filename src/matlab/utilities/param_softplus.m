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
% Find where the signal first exceeds the noise_floor by a
% fraction of the total range
signal_range = max(cur_data) - cur_data(1) ;
amp_range = max(amp_vec) - min(amp_vec);
rise_idx = find(cur_data > (cur_data(1) + 0.2*signal_range), 1, 'first');
if isempty(rise_idx)
    rise_idx = round(length(amp_vec)/2);
end

% Init
x0_init = amp_vec(rise_idx);
x0_init = min(x0_init, median(amp_vec));

upper_span = max(max(amp_vec) - x0_init, 0.1*amp_range);
a_init = (max(cur_data) - cur_data(rise_idx)) / upper_span; % Slope of the upper arrm
k_init = 5 / upper_span;
p0 = [a_init,k_init,x0_init];

% Upper/lower bound
lb = [0, 0.5/upper_span, min(amp_vec) - range(amp_vec)/2];   % keep k off 0
ub = [Inf, 10/upper_span, max(amp_vec)-5];  % cap knee sharpness

% If we have a free noise floor parameter
if isempty(noise_floor)
    p0 = [p0 min(cur_data)];
    lb = [lb min(cur_data) - 0.5*range(cur_data)];
    ub = [ub max(cur_data)];
end

%% Fit model
[p, ~, r, exitflag, ~, ~, J] = lsqcurvefit(@(p,x) softplus(p,x).*weight_vec, p0, ...
    amp_vec, cur_data.*weight_vec, lb, ub, optimset('Display','off'));

%% Identify trials with pinned or non-converged fits
pinned = (isfinite(lb) & abs(p-lb) <= 1e-6*max(1,abs(lb))) | ...
         (isfinite(ub) & abs(p-ub) <= 1e-6*max(1,abs(ub)));
fit_ok = exitflag > 0 && ~any(pinned);