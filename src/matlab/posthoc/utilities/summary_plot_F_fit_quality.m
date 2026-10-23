%% summary_plot_F_fit_quality
% Filter dataset
sub_T = T_F_fitq(ismember(T_F_fitq.Freq, freq_inc) & ...
    ismember(T_F_fitq.Chan, chan_inc),:);

% All Data
% Set up figure
figure;
tiledlayout(2,3,'TileSpacing','tight','Padding','tight')

% Resnorm
nexttile
boxchart(categorical(sub_T.Freq), sub_T.Resnorm_All,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('SSE (\muV)')
title('Total Squared Errors of Fit')

% Number of pins
nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_a_All,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('a')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_k_All,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('k')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_x0_All,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('x0')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_b_All,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('b')
legend({'Subcranial','Subcutaneous'}, 'Location','northwest', 'Box','off')
sgtitle('log10(F) Stat Fit Quality (All Data)')

% Sim Lower Asymptote
% Set up figure
figure;
tiledlayout(2,3,'TileSpacing','tight','Padding','tight')

% Resnorm
nexttile
boxchart(categorical(sub_T.Freq), sub_T.Resnorm_Sim,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('SSE')
title('Total Squared Errors of Fit')

% Number of pins
nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_a_Sim,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('a')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_k_Sim,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('k')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_x0_Sim,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('x0')

nexttile
boxchart(categorical(sub_T.Freq), sub_T.Pin_b_Sim,'GroupByColor', sub_T.Chan)
xlabel('Frequency (Hz)'); ylabel('N Pins')
title('b')
legend({'Subcranial','Subcutaneous'}, 'Location','northwest', 'Box','off')
sgtitle('log10(F) Fit Quality (Simulated Lower Asymptote)')
