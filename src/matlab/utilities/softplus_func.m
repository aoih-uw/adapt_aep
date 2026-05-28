function y = softplus_func(p, x)
y = p(1)*log1p(exp(p(3)*(x - p(2))))/p(3) + p(4);