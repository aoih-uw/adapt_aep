%% summary_endorgan_comparisons
% Get data
addpath 'D:\2026\Research\Aug Sept Midshipman\endorgan_data'
T = readtable('all_endorgans_20261026.xlsx');

% Convert cells to categories
T = convertvars(T, @iscellstr, 'categorical');
T.End_Organ = renamecats(T.End_Organ, {'aep_subcranial','aep_subcutaneous'}, {'subcranial','subcutaneous'});

% Only analyze Pascal data
sub_T = T(T.dB_Reference =='1_micro_Pa',:);

% Only include males and non-reproductive females
mask = sub_T.Sex == "F" & sub_T.Reproductive == 1;
sub_T = sub_T(~mask,:);

% Only include Frequencies up to 410 Hz
sub_T = sub_T(sub_T.Frequency_Hz <= 410,:);

% Calculate the Median across all saccule locations for Sisneros2006
sisneros2006 = sub_T(sub_T.Study == "Sisneros2006",:);
sisneros_median = groupsummary(sisneros2006,'Frequency_Hz',"median",["Threshold","Lower_Error","Upper_Error"]);
sisneros_median = removevars(sisneros_median,"GroupCount");
sisneros_median = renamevars(sisneros_median,["median_Threshold" "median_Lower_Error" "median_Upper_Error"], ...
                   ["Threshold" "Lower_Error" "Upper_Error"]);
sisneros_median.Study = repmat('Sisneros2006',size(sisneros_median,1),1);
sisneros_median.Study = categorical(string(sisneros_median.Study), ["Sisneros2006"]);
sisneros_median.End_Organ = repmat('saccule',size(sisneros_median,1),1);
sisneros_median.End_Organ = categorical(string(sisneros_median.End_Organ), ["saccule"]);
sisneros_median.Properties.VariableNames = {'Frequency_Hz','Threshold','Lower_Error','Upper_Error','Study','End_Organ'};
sisneros_median.Amp_Type = repmat(sisneros2006.Amp_Type(1), height(sisneros_median), 1);

% Delete sisneros2006 from original table
mask = sub_T.Study == "Sisneros2006";
sub_T(mask,:) = [];

% Add in the median across all saccule location
sub_T = outerjoin(sub_T,sisneros_median,'MergeKeys',true);

% Correct peak-peak amplitudes to rms amplitude
% For a sinusoid
cur_idx = find(sub_T.Amp_Type == 'pk-pk');
sub_T.Threshold(cur_idx) = sub_T.Threshold(cur_idx)-20*log10(2*sqrt(2));
sub_T.Lower_Error(cur_idx) = sub_T.Lower_Error(cur_idx)-20*log10(2*sqrt(2));
sub_T.Upper_Error(cur_idx) = sub_T.Upper_Error(cur_idx)-20*log10(2*sqrt(2));

% Plot by end organ
g = categories(sub_T.Study);

% Plot
% Text
lab_y = []; lab_txt = strings(0); lab_c = {};

figure;
for i = 1:length(g)
    tmp_T = sub_T(sub_T.Study == g{i},:);
    gg = unique(tmp_T.End_Organ);
    
    for ii = 1:length(gg)
        tmp_T_2 = sortrows(tmp_T(tmp_T.End_Organ == gg(ii),:), 'Frequency_Hz');
        % Set color
        if tmp_T_2.End_Organ(1) == 'subcranial'
            cur_color = tableau_10('teal');
            cur_thic = 1.5;
        elseif  tmp_T_2.End_Organ(1) == 'subcutaneous'
            cur_color = tableau_10('yellow');
            cur_thic = 1.5;
        else
            cur_color = tableau_10('grey');
            cur_thic = .5;
        end

        errorbar(tmp_T_2.Frequency_Hz,tmp_T_2.Threshold,tmp_T_2.Threshold-tmp_T_2.Lower_Error,tmp_T_2.Upper_Error-tmp_T_2.Threshold,'-o','MarkerFaceColor',cur_color,'Color',cur_color, 'LineWidth',cur_thic);
        lab_y(end+1) = tmp_T_2.Threshold(end);
        lab_txt(end+1) = string(gg(ii)) + " " + g{i};
        lab_c{end+1} = cur_color;
        hold on;
    end
end

% Text
% Spread labels so they are at least `gap` dB apart
[lab_y, o] = sort(lab_y); lab_txt = lab_txt(o); lab_c = lab_c(o);
gap = 1.5;   % dB; increase if labels still touch
for k = 2:numel(lab_y)
    lab_y(k) = max(lab_y(k), lab_y(k-1) + gap);
end
for k = 1:numel(lab_y)
    text(415, lab_y(k), lab_txt(k), 'Color', lab_c{k}, 'Interpreter','none','FontSize',8);
end
xlim([40 500])
xlabel('Frequency (Hz)')
ylabel('Threshold (dB re: 1\muPa)')
title('Auditory end-organ and AEP threshold comparison')