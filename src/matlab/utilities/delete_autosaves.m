function delete_autosaves(folder, filename_root)
    patterns = {sprintf('%s*AUTOSAVE*.mat', filename_root)};
    files = dir(fullfile(folder, patterns{1}));
    for i = 1:length(files)
        delete(fullfile(folder, files(i).name));
        fprintf('\nDeleted autosave: %s\n', files(i).name);
    end
end