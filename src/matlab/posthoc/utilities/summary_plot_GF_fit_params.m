%% summary_plot_GF_fit_params
sub_p = T_mp(ismember(T_mp.Chan,chan_inc)  ...
    & ismember(T_mp.Freq, freq_inc),:);

figure; tiledlayout(1,4,'TileSpacing','tight','Padding','tight');
colororder([tableau_10('blue'); tableau_10('orange')])

% a
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.a_All, "GroupByColor",sub_p.Chan)
title('Upper arm slope (a)')
xlabel('Frequency')
ylabel('a')

% k
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.k_All, "GroupByColor",sub_p.Chan)
title('Bend sharpness (k)')
xlabel('Frequency')
ylabel('k')

% x0
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.x0_All, "GroupByColor",sub_p.Chan)
title('Bend location (x0)')
xlabel('Frequency')
ylabel('x0')
ylim([105 150])

% b
nexttile;
boxchart(categorical(sub_p.Freq), sub_p.b_All, "GroupByColor",sub_p.Chan)
title('Noise floor (b)')
xlabel('Frequency')
ylabel('b')

legend({'Subcranial','Subcutaneous'}, 'Location','northwest', 'Box','off')