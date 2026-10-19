function [p, logistic, fq] = param_logistic(cur_data, amp_vec)
% Fits a 4-parameter logistic to data vs. stimulus amplitude
% p = [A (height), k (steepness), x0 (midpoint), base (noise floor)]
% Gompertz line where the s shape bends more sharply at the bottom than the
% top
logistic = @(p,x) p(1).*exp(-exp(-p(2).*(x - p(3)))) + p(4); 
% Starting guesses
base = cur_data(1);
A_init = max(cur_data) - base;
amp_range = max(amp_vec) - min(amp_vec);
mid_idx = find(cur_data > base + 0.5*A_init, 1, 'first'); % First point past halfway up
if isempty(mid_idx)
    mid_idx = round(length(amp_vec)/2);
end
x0_init = amp_vec(mid_idx);
upper_span = max(max(amp_vec) - x0_init, 0.1*amp_range);
p0 = [A_init, 4/upper_span, x0_init, base];

% Bounds
lb = [0, 0.5/upper_span, min(amp_vec), min(cur_data)];
ub = [Inf, 10/upper_span, max(amp_vec), max(cur_data)];

% Fit and flag parameters stuck at a bound
[p, fq.resnorm, ~, fq.exitflag] = lsqcurvefit(logistic, p0, amp_vec, cur_data, lb, ub, optimset('Display','off'));
fq.pinned = abs(p - lb) < 1e-6 | abs(p - ub) < 1e-6;