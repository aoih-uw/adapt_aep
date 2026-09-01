function grand_ex_save = posthoc_load_my_file(subjid,base_dir,file_type)
% Assign vars
cd(base_dir)
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

grand_ex_save = {};
count = 0;
for iname = 1:numel(my_names)
    current_file = my_names{iname};
    fprintf('Loading %s, %d/%d\n', current_file, iname, numel(my_names))
    try
        S = load(current_file);
        count = count + 1;
        grand_ex_save{count} = S.ex_save;
    catch ME
        fprintf('  Skipping %s: %s\n', current_file, ME.message);
    end
end