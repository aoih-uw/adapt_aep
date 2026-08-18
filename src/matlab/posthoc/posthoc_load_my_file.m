% Assign vars
clearvars
addpath(genpath('\\wsl.localhost\ubuntu\home\aoih\adapt_aep\src\matlab'))
subjid = 1;
base_dir = 'D:\2026\Research\August Midshipman';
cd(base_dir)
file_type = 'mixed_stimuli';
% file_type = 'benzo';
stim_freq = [];
stim_amp = [];

% Setup filename
if isempty(stim_freq), stim_freq = '*'; else stim_freq = sprintf('%dHz', stim_freq); end
if isempty(stim_amp),    stim_amp    = '*'; else stim_amp    = sprintf('%ddBSPL',stim_amp);    end
if isempty(file_type), file_type = '*'; end

% Get file names
subject_folder = sprintf('*_%d*', subjid);
current_folder = dir(subject_folder);
my_path = sprintf('%s/%s/%s', base_dir,current_folder.name, file_type);
cd(my_path)
if isempty(subjid),    subjid    = '*'; else subjid    = num2str(subjid);    end
files = dir(sprintf('*%s_%s_*_%s_%s*', subjid, stim_freq, stim_amp, file_type));
if isempty(files)
    fprintf('No files found')
else
    my_names = {files.name};
end

% Load in files
for iname = 1:size(my_names,2)
current_file = my_names{iname};
fprintf('Loading %s, %d/%d\n',current_file, iname, length(my_names))
try
S = load(current_file);
ex = S.ex_save;
grand_ex_save{iname} = ex;
catch
    disp(ME.message)
    keyboard
end
end
