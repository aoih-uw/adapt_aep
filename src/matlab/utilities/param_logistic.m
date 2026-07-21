function [p, cur_data, cur_data_sem, logistic] = param_logistic(cur_data, cur_data_sem, amp_vec, noise_floor)
% noise_floor = if user does not input, it uses the actual noise floor of
% the data (first data point y value)

if isempty(noise_floor)
    noise_floor = cur_data(1);
end

logistic = @(p,x) p(1)./(1 + exp(-p(2).*(x - p(3)))) + noise_floor;

signal_range = max(cur_data) - cur_data(1);
amp_range = max(amp_vec) - min(amp_vec);

% midpoint init: where signal first crosses half the total range
mid_idx = find(cur_data > (cur_data(1) + 0.5*signal_range), 1, 'first');
if isempty(mid_idx)
    mid_idx = round(length(amp_vec)/2);
end
x0_init = amp_vec(mid_idx);
upper_span = max(max(amp_vec) - x0_init, 0.1*amp_range);

A_init = max(cur_data) - noise_floor;
k_init = 4 / upper_span;
p0 = [A_init, k_init, x0_init];

lb = [0, 0.5/upper_span, min(amp_vec)];
ub = [Inf, 10/upper_span, max(amp_vec)];

p = lsqcurvefit(logistic, p0, amp_vec, cur_data, lb, ub, optimset('Display','off'));