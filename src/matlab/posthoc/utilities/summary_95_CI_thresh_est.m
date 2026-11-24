%% summary_95_CI_thresh_est
% Filter
sub_T = T_thresh(ismember(T_thresh.Chan,chan_inc) & ...
    ismember(T_thresh.Freq,freq_inc), :);
sub_T.CI_range = sub_T.Boot_UpCI - sub_T.Boot_LowCI;

% Only include subjects where there was a threshold found for them
sub_T(isnan(sub_T.All),:) = [];

% Plop
figure;
my_color_order = [tableau_10('teal'); tableau_10('yellow')];
colororder(my_color_order)

freq = categorical(sub_T.Freq);
x = double(freq);                      % 1, 2, 3... for each frequency
g = findgroups(sub_T.Chan);            % 1 or 2 for each channel
boxchart(freq, sub_T.CI_range, "GroupByColor", sub_T.Chan, "MarkerStyle", "none")
hold on

xlabel('Frequency (Hz)')
ylabel('Threshold Estimate Range (dB)')
title('95% CI Threshold Estimate')
legend({'Subcranial','Subcutaneous'}, 'Location','northwest', 'Box','off')

% Add subject count annotations
f = unique(sub_T.Freq); ch = unique(sub_T.Chan);
yl = ylim; ylim([yl(1)-0.1*diff(yl) yl(2)]);
xl = gca().XAxis.NumericLimits;
d = 0.25;
for i = 1:numel(f)
    for j = 1:numel(ch)
        n = sum(sub_T.Freq==f(i) & ismember(sub_T.Chan,ch(j)));
        text((i+(j-1.5)*d-xl(1))/diff(xl), 0.04, string(n), 'Units','normalized', ...
            'HorizontalAlignment','center','FontSize',10,'Color',tableau_10('grey'))
    end
end

ylim([0 14])