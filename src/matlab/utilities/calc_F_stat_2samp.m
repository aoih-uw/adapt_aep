function my_F_stats = calc_F_stat_2samp(vals_ON, vals_OFF)
% Two-sample circular T^2 (Victor & Mast 1991): are the ON and OFF cloud centers different?
n1 = numel(vals_ON);
n2 = numel(vals_OFF);

% Distance between the two cloud centers (squared)
d2 = abs(mean(vals_ON) - mean(vals_OFF))^2;

% Spread of each cloud around its own center, added together
SS = sum(abs(vals_ON - mean(vals_ON)).^2) + sum(abs(vals_OFF - mean(vals_OFF)).^2);

% Calculate F statistic
F = (n1+n2-2) * (n1*n2/(n1+n2)) * d2 / SS;

% Calculate p value
p = fcdf(F, 2, 2*(n1+n2-2), 'upper');

my_F_stats = [F p];