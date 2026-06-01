softplus = @(p,x) p(1)*log1p(exp(p(3)*(x - p(2))))/p(3) + noise_floor_median;
p0 = [(max(response_sorted)-min(response_sorted))/range(amplitude_sorted), ...
    median(amplitude_sorted), 1];
p = lsqcurvefit(softplus, p0, amplitude_sorted, response_sorted, [], [], optimset('Display','off'));
a1_fit = p(1);
x0_fit = p(2);
k_fit  = p(3);
y_int  = noise_floor_median;
target = a1_fit*0.05;
x_10 = x0_fit + log(target/(a1_fit - target)) / k_fit;