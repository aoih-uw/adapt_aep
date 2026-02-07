function y = elbow_function(x,x0, a1, m)
% x = input value
% a1 = noise floor
% x0 = elbow point
% m = slope
y = zeros(size(x));
y(x <= x0) = a1;
y(x > x0) = m*(x(x > x0) - x0) + a1;
end