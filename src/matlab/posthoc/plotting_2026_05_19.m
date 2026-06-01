function plotting_2026_05_19()
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))

cd('F:\2026\Research\May Midshipman\2026_05_15\hydrolagus_colliei_9_20260515')
% Get files
clear all
subjid = 9;
files = dir(sprintf('*%d_*_session_data*', subjid));
mynames = {files.name};

colors = struct( ...
    'blue',   [87  120 164], ...
    'orange', [228 148 68],  ...
    'red',    [209 97  93],  ...
    'teal',   [133 182 178], ...
    'green',  [106 159 88],  ...
    'yellow', [231 202 96],  ...
    'purple', [168 124 159], ...
    'pink',   [241 162 169], ...
    'brown',  [150 118 98],  ...
    'grey',   [184 176 172]  ...
    );

tic()
for iname = 1:length(mynames)
    current_file = mynames{iname};
    S = load(current_file);
    ex_save = S.ex_save;
    freq(iname) = ex_save.stimulus_frequency;
end

% Sort the data by frequency
[~ , sorted_idx] = sort(freq);
freq = freq(sorted_idx);

for iname = 1:length(mynames)
    current_file = mynames{sorted_idx(iname)};
    S = load(current_file);
    ex_save = S.ex_save;
    % 2f vecs
    stim_ON_2f_vec{iname} = ex_save.model.stim_ON_2f_vec;
    stim_OFF_2f_vec{iname} = ex_save.model.stim_OFF_2f_vec;
    diff_2f_vec{iname} = ex_save.model.diff_2f_vec;

    % Models
    amp_vec{iname} = ex_save.model.amplitude_vec_sorted;
    resp_vec{iname} = ex_save.model.response_vec_sorted;
    resp_err{iname} = ex_save.model.response_vec_std_sorted;
    noise_vec{iname} = ex_save.model.per_amp_noise_sorted;
    noise_err{iname} = ex_save.model.per_amp_noise_mad_sorted;
    resp_found_vec{iname} = ex_save.model.resp_found_sorted;
    noise_median(iname) = median(noise_vec{iname});

    % Elbow parameters
    x0_fit{iname} = ex_save.model.x0_fit;
    a1_fit{iname} = ex_save.model.a1_fit;
    m_fit{iname} = ex_save.model.m_fit;
    y_int{iname} = ex_save.model.y_int;
    r_sqr{iname} = ex_save.model.Rsquared;
    gp_thresh{iname} = ex_save.model.gp_threshold;
end

toc()

%% Slope calculation
for iname = 1:length(mynames)
    [uniq_amp, ~, grp] = unique(amp_vec{iname});
    mean_resp = accumarray(grp, resp_vec{iname}(:), [], @mean);
    slope_vec{iname} = diff(mean_resp) ./ diff(uniq_amp)';
end

figure;
tiledlayout('flow', 'TileSpacing','tight', 'Padding','tight');
for iname = 1:length(mynames)
    nexttile
    plot(slope_vec{iname},'o-')
    xlabel('ith comparison')
    ylabel('Slope value')
    title(sprintf('%d Hz', freq(iname)))
end
sgtitle('Derivative Plot')

% Growth functions
figure;
tiledlayout('flow', 'TileSpacing','tight', 'Padding','tight');
for iname = 1:length(mynames)
    nexttile;

    errorbar(amp_vec{iname}, resp_vec{iname}, resp_err{iname}, ...
        'Color',[0.6 0.6 0.6]);
    hold on;

    num_points = length(resp_found_vec{iname});
    for ipoints = 1:num_points
        if resp_found_vec{iname}(ipoints)
            cur_color = colors.green/255;
        else
            cur_color = colors.red/255;
        end
        plot(amp_vec{iname}(ipoints), resp_vec{iname}(ipoints), 'o', ...
            'MarkerFaceColor', cur_color, 'MarkerEdgeColor', cur_color);
    end

    errorbar(amp_vec{iname}, noise_vec{iname}, noise_err{iname}, ...
        'o', 'Color',[184 176 172]/255, 'MarkerFaceColor',colors.grey/255);

    yline(noise_median(iname),'--');
    cur_x0 = x0_fit{iname};
    if ~isempty(cur_x0)
        xline(x0_fit{iname}(end), '--');
    end
    title(sprintf('%d Hz', freq(iname)));
    hold off;
end
sgtitle(sprintf('Subject %d Growth Functions', subjid))
linkaxes(findobj(gcf,'Type','axes'),'xy');

% Exclude data points
exclude_idx = [5,8,9];

keep = setdiff(1:length(mynames), exclude_idx);
freq = freq(keep);
mynames = mynames(keep);
stim_ON_2f_vec  = stim_ON_2f_vec(keep);
stim_OFF_2f_vec = stim_OFF_2f_vec(keep);
diff_2f_vec     = diff_2f_vec(keep);
amp_vec         = amp_vec(keep);
resp_vec        = resp_vec(keep);
resp_err        = resp_err(keep);
noise_vec       = noise_vec(keep);
noise_err       = noise_err(keep);
resp_found_vec  = resp_found_vec(keep);
noise_median    = noise_median(keep);
x0_fit          = x0_fit(keep);
a1_fit          = a1_fit(keep);
m_fit           = m_fit(keep);
y_int           = y_int(keep);
r_sqr           = r_sqr(keep);
gp_thresh       = gp_thresh(keep);


%% Fit softplus
softplus = @(p,x) p(1)*log1p(exp(p(3)*(x - p(2))))/p(3) + p(4);
n = length(amp_vec);
sp_params = cell(1,n);
figure;
nrows = ceil(sqrt(n)); ncols = ceil(n/nrows);
tiledlayout(nrows, ncols, 'TileSpacing','compact', 'Padding','compact');
for i = 1:n
    x = amp_vec{i}(:); y = resp_vec{i}(:);
    p0 = [(max(y)-min(y))/range(x), median(x), 1, min(y)];
    p = lsqcurvefit(softplus, p0, x, y, [], [], optimset('Display','off'));
    sp_params{i} = p;
    x_10(i) = p(2) - log(9)/p(3);
    nexttile;
    xx = linspace(min(x), max(x), 200);
    plot(xx, softplus(p,xx), '-','LineWidth',2); hold on;
    plot(x, y, 'o');
    xline(x_10(i), '--');
    title(sprintf('%.1f Hz | x_{10}=%.2f', freq(i), x_10(i)));
end

% %% Fit 2 elbows
% elbow = @(p,x) elbow_2_function(x, p(1), p(2), p(3), p(4), p(5));
% n = length(amp_vec);
% fit_params = cell(1,n);
% figure;
% nrows = ceil(sqrt(n)); ncols = ceil(n/nrows);
% t = tiledlayout(nrows, ncols, 'TileSpacing', 'compact', 'Padding', 'compact');
% for i = 1:n
%     x = amp_vec{i}(:); y = resp_vec{i}(:);
%     p0 = [quantile(x,1/3), quantile(x,2/3), min(y), (max(y)-min(y))/range(x), (max(y)-min(y))/range(x)];
%     lb = [min(x), min(x), -inf, -inf, -inf];
%     ub = [max(x), max(x),  inf,  inf,  inf];
%     p = lsqcurvefit(elbow, p0, x, y, lb, ub, optimset('Display','off'));
%     fit_params{i} = p;
%     nexttile;
%     xx = linspace(min(x), max(x), 200);
%     plot(xx, elbow(p, xx), '-','LineWidth',2); hold on;
%     plot(x, y, 'o');
%     xline(p(1), '--');
%     title(sprintf('%.1f Hz | x0=%.3g', freq(i), p(1)));
% end

%% Elbow functions
for i = 1:length(fit_params)
    x0_2(i) = fit_params{i}(1);
end

figure;
plot(freq,x0_2,'o-')

% one elbow x0 predictions
figure;
for iname = 1:length(mynames)
    cur_x0 = x0_fit{iname};
    if ~isempty(cur_x0)
        scatter(freq(iname), x0_fit{iname}(end), 100,colors.blue/255, 'filled');
    end
    hold on;
end
xlim([min(freq)-min(freq)*.2 max(freq)+max(freq)*.2]);
xticks(unique(freq))
xscale('log')
xlabel('Stimulus Frequency (Hz)')
ylabel('Threshold dB SPL')
title('x0 values')

% Smallest Bootstrap Threshold
for iname = 1:length(mynames)
    myidx = find(resp_found_vec{iname},1,'first');
    if ~isempty(myidx)
        if ~isempty(myidx) ...
                && myidx+1 <= length(amp_vec{iname}) ...
                && amp_vec{iname}(myidx+1) == 0
            thresh_val(iname) = NaN;
        else
            thresh_val(iname) = amp_vec{iname}(myidx);
        end
    else
        thresh_val(iname) = NaN;
    end
end

figure;
for iname = 1:length(mynames)
    cur_x0 = x0_fit{iname};
    if ~isempty(cur_x0)
        scatter(freq(iname), thresh_val(iname), 100,colors.blue/255, 'filled');
    end
    hold on;
end
xlim([min(freq)-min(freq)*.2 max(freq)+max(freq)*.2]);
xticks(unique(freq))
xscale('log')
xlabel('Stimulus Frequency (Hz)')
ylabel('Threshold dB SPL')
title('Smallest Boot')
