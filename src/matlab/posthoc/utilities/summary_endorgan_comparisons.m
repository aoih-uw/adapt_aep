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

% Delete sisneros2006 from original table
mask = sub_T.Study == "Sisneros2006";
sub_T(mask,:) = [];

% Add in the median across all saccule location
sub_T = outerjoin(sub_T,sisneros_median,'MergeKeys',true);

% Plot by end organ
g = categories(sub_T.Study);

% Plot
figure;
for i = 1:length(g)
    tmp_T = sub_T(sub_T.Study == g{i},:);
    gg = unique(tmp_T.End_Organ);
    
    for ii = 1:length(gg)
        tmp_T_2 = tmp_T(tmp_T.End_Organ == gg(ii),:);
        % Set color
        if tmp_T_2.End_Organ(1) == 'subcranial'
            cur_color = tableau_10('blue');
            cur_thic = 1.5;
        elseif  tmp_T_2.End_Organ(1) == 'subcutaneous'
            cur_color = tableau_10('orange');
            cur_thic = 1.5;
        else
            cur_color = tableau_10('grey');
            cur_thic = .5;
        end

        errorbar(tmp_T_2.Frequency_Hz,tmp_T_2.Threshold,tmp_T_2.Lower_Error-tmp_T_2.Threshold,tmp_T_2.Upper_Error-tmp_T_2.Threshold,'-o','MarkerFaceColor',cur_color,'Color',cur_color, 'LineWidth',cur_thic);
        text(tmp_T_2.Frequency_Hz(end) + 5, tmp_T_2.Threshold(end), [gg(ii) g(i)], ...
            'Color', cur_color, 'Interpreter', 'none','FontSize',8);
        hold on;
    end
end
xlim([40 420])
xlabel('Frequency (Hz)')
ylabel('Threshold (dB re: 1\muPa)')
title('Auditory end-organ and AEP threshold comparison')