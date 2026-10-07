function [my_names] = find_files(subjid,base_dir,stim_freq,stim_amp,file_type, is_raw)
% Returns full paths of matching files for exactly this subject ID

% Setup filename
if isempty(stim_freq), stim_freq = '*'; else, stim_freq = sprintf('%dHz', stim_freq); end
if isempty(stim_amp),  stim_amp  = '*'; else, stim_amp  = sprintf('%ddBSPL', stim_amp); end
if isempty(file_type), file_type = '*'; end
subjid = num2str(subjid);

my_names = {};
if is_raw
    % Folder name must end in _<id>_<8-digit date>
    folders = dir(fullfile(base_dir, sprintf('*_%s_*', subjid)));
    folders = folders([folders.isdir] & ~cellfun(@isempty, ...
        regexp({folders.name}, ['_' subjid '_\d{8}$'], 'once')));

    % Same subject can be tested on several days, so collect from every folder
    for k = 1:numel(folders)
        my_path = fullfile(base_dir, folders(k).name, file_type);
        files = dir(fullfile(my_path, sprintf('*_%s_%s_*_%s_%s*', subjid, stim_freq, stim_amp, file_type)));
        my_names = [my_names, fullfile(my_path, {files.name})];
    end
else % Sorted data
    files = dir(fullfile(base_dir, sprintf('subject_%s_%s*', subjid, file_type)));
    my_names = fullfile(base_dir, {files.name});
end

if isempty(my_names), fprintf('No files found for subject %s\n', subjid); end
end