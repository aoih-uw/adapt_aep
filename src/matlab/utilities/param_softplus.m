function [p, cur_data, cur_data_sem, softplus]  = param_softplus(cur_data, cur_data_sem, amp_vec, noise_floor)
% noise_floor = if user does not input, it uses the actual noise floor of
% the data (first data point y value)
% sub in quadrature

if isempty(noise_floor)
    noise_floor = cur_data(1);
end

softplus = @(p,x) (p(1)/p(2))*(log1p(exp(p(2).*(x-p(3))))) + noise_floor;

% Find where the signal first exceeds the noise_floor by a
% fraction of the total range
signal_range = max(cur_data) - cur_data(1) ;
amp_range = max(amp_vec) - min(amp_vec);

rise_idx = find(cur_data > (cur_data(1) + 0.2*signal_range), 1, 'first');
if isempty(rise_idx)
    rise_idx = round(length(amp_vec)/2);
end
x0_init = amp_vec(rise_idx);
upper_span = max(max(amp_vec) - x0_init, 0.1*amp_range);

a_init = (max(cur_data) - cur_data(rise_idx)) / upper_span; % Slope of the upper arrm
k_init = 4 / upper_span;
p0 = [a_init,k_init,x0_init];

lb = [0, 0.5/upper_span, min(amp_vec)];   % keep k off 0
ub = [Inf, 10/upper_span, max(amp_vec)-5];  % cap knee sharpness

p = lsqcurvefit(softplus,p0,amp_vec,cur_data,lb,ub,optimset('Display','off'));
