function delete_autosaves(folder, filename_root)
%% Finds files within the current subject folder and deletes and files that contains "AUTOSAVE" in the name
    patterns = {sprintf('%s*AUTOSAVE*.mat', filename_root)};
    files = dir(fullfile(folder, patterns{1}));
    for i = 1:length(files)
        delete(fullfile(folder, files(i).name));
        fprintf('\nDeleted autosave: %s\n', files(i).name);
    end
end