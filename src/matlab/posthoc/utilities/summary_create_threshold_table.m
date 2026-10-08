%% summary_create_threshold_table
sub_T = T_rf(T_rf.CI == 99 ...
    & T_rf.Boot_It_N == 5000 ...
    & ismember(T_rf.Chan,chan_inc) ...
    & ismember(T_rf.Freq,freq_inc),:);
sub_T.Chan = removecats(sub_T.Chan);

%% Fix so it finds that for each subject there was at least one amplitude where there was no response found in order to select a threshold value
% Find heatmap based threshold
% You need to filter by rows that are below max_trials first since split apply needs a value per group, it cannot be empty
% Find groups finds the locations of unique combinations of the variables
% you input (Find every unique combo of subject and Frequency and Chan) so
% then you can analyze the result value of interest based on each unique
% group type
subjids = unique(sub_T.Subj_ID);
my_table = [];
for isubj = 1:length(subjids)
    cur_subj = subjids(isubj);
    for ifreq = 1:length(freq_inc)
        cur_freq = freq_inc(ifreq);
        for ichan = 1:length(chan_inc)
            cur_chan = chan_inc(ichan);

            cur_T = sub_T(sub_T.Subj_ID == cur_subj & ...
                sub_T.Freq == cur_freq & ...
                sub_T.Chan == cur_chan, :);

            % Find idx values where max limit was met
            max_limit_met = cur_T.First == max_trials;
            no_resp_found = find(max_limit_met);
            % No threshold found if...
            % 1. Response was found at all tested amplitudes OR
            % 2. No response was found at any amplitude
            if isempty(no_resp_found) || (length(no_resp_found) == length(unique(cur_T.Amp)))
                cur_thresh = NaN;
            else
                right_under_thresh = find(max_limit_met,1,'last');
                % Check that right_under_thresh + 1 not equal to max_trials
                if cur_T.First(right_under_thresh+1) >= max_trials
                    keyboard
                else
                    cur_thresh = cur_T.Amp(right_under_thresh+1);
                end
            end
            my_table = [my_table; cur_subj cur_freq cur_chan cur_thresh];
        end
    end
end

% Convert array to table and adjust column types
T_heat_thresh = array2table(my_table, 'VariableNames',{'Subj_ID', 'Freq', 'Chan', 'Heat_Thresh'});
T_heat_thresh.Subj_ID = str2double(T_heat_thresh.Subj_ID);
T_heat_thresh.Freq = str2double(T_heat_thresh.Freq);
T_heat_thresh.Heat_Thresh = str2double(T_heat_thresh.Heat_Thresh);
T_heat_thresh.Chan = categorical(T_heat_thresh.Chan);

% Find model based threshold
% exclude_subj = [34];
% exclude_freq_for_subj = [55];
sub_T = T_thresh(ismember(T_thresh.Chan,chan_inc) ...
    & ismember(T_thresh.Freq,freq_inc),:); ...
    % & ~(ismember(T_thresh.Subj_ID,exclude_subj) & ismember(T_thresh.Freq,exclude_freq_for_subj)),:);
sub_T.Chan = removecats(sub_T.Chan);
sub_T.Properties.VariableNames{4} = 'Model_Thresh';

%% Compare bootstrap based threshold and model based threshold estimates
% Join tables
% Inner join = only includes rows of data only where there is overlap between the two Tables,
% there is a present threshold value in their respective tables
% Outer join = includes rows where both OR only one table had a value in the
% threshold value
join_T = outerjoin(T_heat_thresh,sub_T,'Keys',{'Subj_ID','Freq','Chan'}, 'MergeKeys',true);
join_T.Freq = categorical(join_T.Freq);