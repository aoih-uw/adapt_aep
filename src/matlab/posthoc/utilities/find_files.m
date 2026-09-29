function [my_names] = find_files(subjid,base_dir,stim_freq,stim_amp,file_type, is_raw)
% Go to target directory
cd(base_dir)

% Setup filename
if isempty(stim_freq), stim_freq = '*';
else
    stim_freq = sprintf('%dHz', stim_freq);
end
if isempty(stim_amp),    stim_amp    = '*';
else stim_amp    = sprintf('%ddBSPL',stim_amp);
end
if isempty(file_type), file_type = '*'; end
if isempty(subjid),    subjid    = '*'; else subjid    = num2str(subjid);    end

% Get file names
if is_raw
    subject_folder = sprintf('*_%s*', subjid);
    current_folder = dir(subject_folder);
    my_path = sprintf('%s/%s/%s', base_dir,current_folder.name, file_type);
    cd(my_path)
    files = dir(sprintf('*%s_%s_*_%s_%s*', subjid, stim_freq, stim_amp, file_type));
else % Sorted data
    files = dir(sprintf('*%s_%s*', subjid, file_type));
end
my_names = {files.name};
if isempty(my_names), fprintf('No files found\n'); end
end