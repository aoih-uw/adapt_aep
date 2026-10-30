function my_F_stats = calc_F_stat_2samp(vals_ON, vals_OFF)
% Paired circular T^2 test (Victor & Mast 1991, one-sample version).
% Question: across trials, is ON consistently different from OFF?
%
% Inputs: complex Fourier values, one per trial. Each value is a dot on a
% "dartboard": distance from center = wave size, angle = wave timing.
% vals_ON(k) and vals_OFF(k) MUST come from the same trial k.

% For each trial, draw an arrow from its OFF dot to its ON dot.
% Noise shared by ON and OFF within a trial cancels out here.
D = vals_ON - vals_OFF;

% Number of trials (number of arrows).
M = numel(D);

% Signal: abs(mean(D))^2 = squared length of the AVERAGE arrow.
%   Phase is taken into acount when we take the mean(D), then AFTER we take
%   the abs() and look at length, allowing random directions of vectors to
%   cancel eachother first, and then we evaluate the magnitude of the
%   average vector
%   If ON and OFF don't differ, arrows point randomly and average out
%   to nearly zero length. A real effect makes them point the same way.

% Noise: sum(abs(D - mean(D)).^2) = how much each arrow strays from the
%   average arrow, squared and added up.

% M*(M-1) scales signal/noise so the result follows an F-distribution:
%   M because averaging M arrows shrinks noise in the mean by a factor of M,
%   (M-1) because computing the mean used up one degree of freedom.

F = M*(M-1) * abs(mean(D))^2 / sum(abs(D - mean(D)).^2);

% p-value: chance of getting an F this large if there were no real effect.
% Degrees of freedom:
%   2       = the average arrow has 2 parts (real and imaginary)
%   2*(M-1) = M arrows, minus 1 for the mean, times 2 parts each
% 'upper' = area to the right of F (the "this large or larger" tail).
p = fcdf(F, 2, 2*(M-1), 'upper');

% Return both the test statistic and its p-value.
my_F_stats = [F p];