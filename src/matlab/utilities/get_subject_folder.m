function subject_folder = get_subject_folder(ex)
%% This function finds or creates the current subject's data folder with a figures subfolder
% Each subject will get their own folder for that day. If the same subject is tested on another day, a separate folder will be created
    base_folder = fullfile('..', '..', 'data', 'aep');
    folder_name = sprintf('%s_%s_%s', ex.info.animal.species_name, string(ex.info.animal.subject_ID), ex.info.experiment.exp_date);
    
    % Add test_tag subfolder
    test_tag = ex.info.experiment.test_tag;
    if isempty(test_tag), test_tag = 'untagged'; end  % fallback safety
    
    subject_folder = fullfile(base_folder, folder_name, test_tag);
    if ~exist(subject_folder, 'dir'), mkdir(subject_folder); end
    figures_folder = fullfile(subject_folder, 'figures');
    if ~exist(figures_folder, 'dir'), mkdir(figures_folder); end
end