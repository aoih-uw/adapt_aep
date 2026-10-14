function my_F_stats = calc_F_stat(vals)
%# Check with someone at eScience to verify circular stats equations
% How many observations do we have?
n_obs = numel(vals);

% Phase locking value
myPLV = abs(mean(vals./abs(vals)));

% R = signal to noise ratio
% Distance of mean cloud center from origin / Sum of distance from each dot to
% mean cloud center
R = n_obs*abs(mean(vals))^2 / sum(abs(vals - mean(vals)).^2);

% Calculate F statistic
F = (n_obs-1)*R;

% Calculate p value
p = 1 - fcdf(F,2,2*(n_obs-1));

% Package into one variable
my_F_stats = [myPLV, R F p];